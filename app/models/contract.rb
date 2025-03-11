class Contract < ApplicationRecord
  belongs_to :project
  has_many :versions, class_name: "Contract", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Contract", optional: true
 
  # Add validation for ARC56 content
  validates :arc56, presence: true
  validate :validate_arc56_format
  
  validates :name, presence: true
  validates :version, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :round_valid_from, presence: true
  validates :app_id, presence: true, numericality: { only_integer: true }
  validates :address, presence: true

  # Returns all versions of this contract (including this one)
  # Sorted by version number
  def all_versions
    # Find the root contract
    root = self
    while root.parent_id.present?
      root = Contract.find(root.parent_id)
    end
    
    # Get all versions starting from the root
    versions = [root]
    find_children(root, versions)
    
    # Sort by version number
    versions.sort_by(&:version)
  end
  
  # Returns the latest version of this contract
  def latest_version
    all_versions.last
  end

  # Creates a new version of the contract
  def create_version(attributes = {})
    new_version = attributes.dup
    new_version[:parent_id] = id
    new_version[:project_id] = project_id
    new_version[:version] = next_version_number(new_version[:version])
    
    # Copy ARC56 content if not provided
    new_version[:arc56] = arc56 if new_version[:arc56].blank?
    
    # Create the new version
    versions.create!(new_version)
  end

  private

  def next_version_number(specified_version = nil)
    return specified_version if specified_version.present?
    
    if versions.any?
      versions.maximum(:version) + 0.1
    else
      version + 0.1
    end
  end

  def validate_arc56_format
    return if arc56.blank?
    
    begin
      json_data = JSON.parse(arc56)
      
      # Check required top-level fields
      required_fields = ['arcs', 'name', 'methods']
      missing_fields = required_fields.select { |field| !json_data.key?(field) }
      
      if missing_fields.any?
        errors.add(:arc56, "is missing required fields: #{missing_fields.join(', ')}")
        return
      end
      
      # Validate name
      if json_data['name'].blank? || !json_data['name'].is_a?(String)
        errors.add(:arc56, "name must be a non-empty string")
      end
      
      # Validate description if present
      if json_data.key?('description') && (!json_data['description'].is_a?(String) || json_data['description'].blank?)
        errors.add(:arc56, "description must be a non-empty string")
      end
      
      # Validate arcs array
      if !json_data['arcs'].is_a?(Array) || json_data['arcs'].empty?
        errors.add(:arc56, "arcs must be a non-empty array")
        return
      end
      
      # Validate all arcs are integers
      json_data['arcs'].each do |arc|
        unless arc.is_a?(Integer)
          errors.add(:arc56, "arcs array must contain only integers, found: #{arc.class}")
        end
      end
      
      # Validate methods array
      if !json_data['methods'].is_a?(Array) || json_data['methods'].empty?
        errors.add(:arc56, "must include at least one method")
        return
      end
      
      # Validate each method
      method_names = Set.new
      json_data['methods'].each_with_index do |method, index|
        # Check required method fields
        method_required_fields = ['name', 'args', 'returns']
        method_missing_fields = method_required_fields.select { |field| !method.key?(field) }
        
        if method_missing_fields.any?
          errors.add(:arc56, "method at index #{index} is missing required fields: #{method_missing_fields.join(', ')}")
        end
        
        # Validate method name
        if method['name'].blank? || !method['name'].is_a?(String)
          errors.add(:arc56, "method at index #{index} must have a non-empty string name")
        elsif method_names.include?(method['name'])
          errors.add(:arc56, "duplicate method name: #{method['name']}")
        else
          method_names.add(method['name'])
        end
        
        # Validate method description if present
        if method.key?('desc') && (!method['desc'].is_a?(String) || method['desc'].blank?)
          errors.add(:arc56, "method '#{method['name']}' description must be a non-empty string")
        end
        
        # Validate args array
        if !method['args'].is_a?(Array)
          errors.add(:arc56, "method '#{method['name']}' args must be an array")
        else
          # Check each arg
          arg_names = Set.new
          method['args'].each_with_index do |arg, arg_index|
            if !arg.is_a?(Hash)
              errors.add(:arc56, "method '#{method['name']}' arg at index #{arg_index} must be an object")
              next
            end
            
            # Check required arg fields
            if !arg.key?('type')
              errors.add(:arc56, "method '#{method['name']}' arg at index #{arg_index} is missing required field: type")
            end
            
            # Validate arg name if present
            if arg.key?('name')
              if arg['name'].blank? || !arg['name'].is_a?(String)
                errors.add(:arc56, "method '#{method['name']}' arg at index #{arg_index} name must be a non-empty string")
              elsif arg_names.include?(arg['name'])
                errors.add(:arc56, "method '#{method['name']}' has duplicate arg name: #{arg['name']}")
              else
                arg_names.add(arg['name'])
              end
            end
            
            # Validate arg type
            validate_type_reference(arg['type'], "method '#{method['name']}' arg at index #{arg_index}", json_data)
            
            # Validate arg description if present
            if arg.key?('desc') && (!arg['desc'].is_a?(String) || arg['desc'].blank?)
              errors.add(:arc56, "method '#{method['name']}' arg at index #{arg_index} description must be a non-empty string")
            end
          end
        end
        
        # Validate returns object
        if !method['returns'].is_a?(Hash)
          errors.add(:arc56, "method '#{method['name']}' returns must be an object")
        elsif !method['returns'].key?('type')
          errors.add(:arc56, "method '#{method['name']}' returns is missing required field: type")
        else
          # Validate return type
          validate_type_reference(method['returns']['type'], "method '#{method['name']}' return", json_data)
          
          # Validate return description if present
          if method['returns'].key?('desc') && (!method['returns']['desc'].is_a?(String) || method['returns']['desc'].blank?)
            errors.add(:arc56, "method '#{method['name']}' return description must be a non-empty string")
          end
        end
        
        # Validate readonly if present
        if method.key?('readonly') && ![true, false].include?(method['readonly'])
          errors.add(:arc56, "method '#{method['name']}' readonly must be a boolean")
        end
      end
      
      # Validate structs if present
      if json_data.key?('structs')
        if !json_data['structs'].is_a?(Hash)
          errors.add(:arc56, "structs must be an object")
        else
          json_data['structs'].each do |struct_name, struct_fields|
            if struct_name.blank?
              errors.add(:arc56, "struct name cannot be empty")
              next
            end
            
            if !struct_fields.is_a?(Array)
              errors.add(:arc56, "struct '#{struct_name}' must be an array of fields")
              next
            end
            
            if struct_fields.empty?
              errors.add(:arc56, "struct '#{struct_name}' must have at least one field")
              next
            end
            
            field_names = Set.new
            struct_fields.each_with_index do |field, field_index|
              if !field.is_a?(Hash)
                errors.add(:arc56, "struct '#{struct_name}' field at index #{field_index} must be an object")
                next
              end
              
              if !field.key?('name') || !field.key?('type')
                errors.add(:arc56, "struct '#{struct_name}' field at index #{field_index} is missing required fields: name and/or type")
                next
              end
              
              # Validate field name
              if field['name'].blank? || !field['name'].is_a?(String)
                errors.add(:arc56, "struct '#{struct_name}' field at index #{field_index} name must be a non-empty string")
              elsif field_names.include?(field['name'])
                errors.add(:arc56, "struct '#{struct_name}' has duplicate field name: #{field['name']}")
              else
                field_names.add(field['name'])
              end
              
              # Validate field type
              validate_type_reference(field['type'], "struct '#{struct_name}' field '#{field['name']}'", json_data)
              
              # Validate field description if present
              if field.key?('desc') && (!field['desc'].is_a?(String) || field['desc'].blank?)
                errors.add(:arc56, "struct '#{struct_name}' field '#{field['name']}' description must be a non-empty string")
              end
            end
          end
        end
      end
      
      # Validate state if present
      if json_data.key?('state')
        if !json_data['state'].is_a?(Hash)
          errors.add(:arc56, "state must be an object")
        else
          state = json_data['state']
          
          # Check schema
          if state.key?('schema')
            if !state['schema'].is_a?(Hash)
              errors.add(:arc56, "state schema must be an object")
            else
              schema = state['schema']
              if !schema.key?('global') || !schema.key?('local')
                errors.add(:arc56, "state schema must include global and local")
              else
                ['global', 'local'].each do |scope|
                  if !schema[scope].is_a?(Hash)
                    errors.add(:arc56, "state schema #{scope} must be an object")
                  elsif !schema[scope].key?('ints') || !schema[scope].key?('bytes')
                    errors.add(:arc56, "state schema #{scope} must include ints and bytes")
                  elsif !schema[scope]['ints'].is_a?(Integer) || schema[scope]['ints'] < 0
                    errors.add(:arc56, "state schema #{scope} ints must be a non-negative integer")
                  elsif !schema[scope]['bytes'].is_a?(Integer) || schema[scope]['bytes'] < 0
                    errors.add(:arc56, "state schema #{scope} bytes must be a non-negative integer")
                  end
                end
              end
            end
          end
          
          # Check storage keys
          if state.key?('keys')
            if !state['keys'].is_a?(Hash)
              errors.add(:arc56, "state keys must be an object")
            else
              keys = state['keys']
              ['global', 'local', 'box'].each do |scope|
                if keys.key?(scope)
                  if !keys[scope].is_a?(Hash)
                    errors.add(:arc56, "state keys #{scope} must be an object")
                  else
                    keys[scope].each do |key_name, key_info|
                      if key_name.blank?
                        errors.add(:arc56, "state key name in #{scope} cannot be empty")
                        next
                      end
                      
                      if !key_info.is_a?(Hash)
                        errors.add(:arc56, "state key '#{key_name}' in #{scope} must be an object")
                        next
                      end
                      
                      required_key_fields = ['keyType', 'valueType', 'key']
                      missing_key_fields = required_key_fields.select { |field| !key_info.key?(field) }
                      
                      if missing_key_fields.any?
                        errors.add(:arc56, "state key '#{key_name}' in #{scope} is missing required fields: #{missing_key_fields.join(', ')}")
                      end
                      

                      # TODO: refactor with avmtypes abitypes ffs
                      # # Validate keyType
                      # if key_info.key?('keyType') && !['ABIType','AVMType','StructName'].include?(key_info['keyType'])
                      #   errors.add(:arc56, "state key '#{key_name}' in #{scope} keyType must be 'static' or 'dynamic'")
                      # end
                      
                      # Validate valueType
                      if key_info.key?('valueType')
                        validate_type_reference(key_info['valueType'], "state key '#{key_name}' in #{scope}", json_data)
                      end
                      
                      # Validate key
                      if key_info.key?('key') && key_info['key'].blank? && key_info['keyType'] == 'static'
                        errors.add(:arc56, "state key '#{key_name}' in #{scope} with static keyType must have a non-empty key")
                      end
                      
                      # Validate description if present
                      if key_info.key?('desc') && (!key_info['desc'].is_a?(String) || key_info['desc'].blank?)
                        errors.add(:arc56, "state key '#{key_name}' in #{scope} description must be a non-empty string")
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      
      # Validate events if present
      if json_data.key?('events')
        if !json_data['events'].is_a?(Array)
          errors.add(:arc56, "events must be an array")
        else
          event_names = Set.new
          json_data['events'].each_with_index do |event, index|
            if !event.is_a?(Hash)
              errors.add(:arc56, "event at index #{index} must be an object")
              next
            end
            
            if !event.key?('name') || !event.key?('args')
              errors.add(:arc56, "event at index #{index} is missing required fields: name and/or args")
              next
            end
            
            # Validate event name
            if event['name'].blank? || !event['name'].is_a?(String)
              errors.add(:arc56, "event at index #{index} name must be a non-empty string")
            elsif event_names.include?(event['name'])
              errors.add(:arc56, "duplicate event name: #{event['name']}")
            else
              event_names.add(event['name'])
            end
            
            # Validate event description if present
            if event.key?('desc') && (!event['desc'].is_a?(String) || event['desc'].blank?)
              errors.add(:arc56, "event '#{event['name']}' description must be a non-empty string")
            end
            
            # Validate args array
            if !event['args'].is_a?(Array)
              errors.add(:arc56, "event '#{event['name']}' args must be an array")
            else
              arg_names = Set.new
              event['args'].each_with_index do |arg, arg_index|
                if !arg.is_a?(Hash)
                  errors.add(:arc56, "event '#{event['name']}' arg at index #{arg_index} must be an object")
                  next
                end
                
                # Check required arg fields
                if !arg.key?('type')
                  errors.add(:arc56, "event '#{event['name']}' arg at index #{arg_index} is missing required field: type")
                end
                
                # Validate arg name if present
                if arg.key?('name')
                  if arg['name'].blank? || !arg['name'].is_a?(String)
                    errors.add(:arc56, "event '#{event['name']}' arg at index #{arg_index} name must be a non-empty string")
                  elsif arg_names.include?(arg['name'])
                    errors.add(:arc56, "event '#{event['name']}' has duplicate arg name: #{arg['name']}")
                  else
                    arg_names.add(arg['name'])
                  end
                end
                
                # Validate arg type
                validate_type_reference(arg['type'], "event '#{event['name']}' arg at index #{arg_index}", json_data)
                
                # Validate arg description if present
                if arg.key?('desc') && (!arg['desc'].is_a?(String) || arg['desc'].blank?)
                  errors.add(:arc56, "event '#{event['name']}' arg at index #{arg_index} description must be a non-empty string")
                end
              end
            end
          end
        end
      end
      
    rescue JSON::ParserError
      errors.add(:arc56, 'contains invalid JSON')
    rescue => e
      errors.add(:arc56, "validation error: #{e.message}")
    end
  end

  # Helper method to validate type references
  def validate_type_reference(type, context, json_data)
    return if type.blank?
    
    # Basic types
    basic_types = [
      'uint8', 'uint16', 'uint32', 'uint64', 'uint128', 'uint256',
      'byte', 'bytes', 'string', 'address', 'bool', 'void', 'AVMString',
      'pay', 'account', 'application', 'asset', 'AVMBytes', 'AVMUint64'
    ]
    
    # Check if it's an array type
    if type.end_with?('[]')
      base_type = type[0...-2]
      validate_type_reference(base_type, "#{context} array element", json_data)
      return
    end
    
    # Check if it's a tuple type
    if type.start_with?('(') && type.end_with?(')')
      tuple_types = type[1...-1].split(',').map(&:strip)
      tuple_types.each_with_index do |tuple_type, i|
        validate_type_reference(tuple_type, "#{context} tuple element #{i+1}", json_data)
      end
      return
    end
    
    # Check if it's a basic type or a defined struct
    unless basic_types.include?(type) || (json_data.key?('structs') && json_data['structs'].key?(type))
      errors.add(:arc56, "#{context} has invalid type: #{type}")
    end
  end

  # Recursively find all child contracts
  def find_children(contract, versions_array)
    children = Contract.where(parent_id: contract.id)
    children.each do |child|
      versions_array << child
      find_children(child, versions_array)
    end
  end
end
