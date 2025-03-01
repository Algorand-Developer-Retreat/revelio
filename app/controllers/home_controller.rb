class HomeController < ApplicationController
  skip_before_action :authenticate, only: :landing

  def landing
    @projects = Project.all
  end
  def feed
    @projects = Project.all
  end

  def about
  end

  def docs
  end
end

