class HomeController < ApplicationController
  skip_before_action :authenticate, only: :landing

  def landing
    @projects = Project.all
  end
  def feed
    @projects = Project.all
    @contracts = Contract.includes(:project).order(created_at: :desc).limit(20)
  end

  def about
  end

  def docs
  end
end

