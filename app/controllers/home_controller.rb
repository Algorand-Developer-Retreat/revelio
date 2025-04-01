class HomeController < ApplicationController
  skip_before_action :authenticate, only: :landing

  def landing
    @projects = Project.all
  end

  def feed
    @projects = Project.all
    @contracts = Contract.includes(:project).order(created_at: :desc).limit(20)
    @breadcrumbs = [{ name: "Home", path: root_path }, { name: "Feed", path: feed_path }]
  end

  def about
    @breadcrumbs = [{ name: "Home", path: root_path }, { name: "About", path: about_path }]
  end

  def docs
    @breadcrumbs = [{ name: "Home", path: root_path }, { name: "Docs", path: docs_path }]
  end
end

