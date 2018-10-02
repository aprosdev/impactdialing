##
class Report::Dials::ByStatusController < Ruport::Controller
  # hack
  Report::Formatters::Html # ? formatters aren't loading => aren't declaring themselves to controllers

  stage :heading, :description, :table

  required_option :campaign, :description, :scoped_to

public
  def setup
    self.data = Report::Dials::ByStatus.new(options).make
  end
end

