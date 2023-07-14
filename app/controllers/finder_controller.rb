class FinderController < ApplicationController
  before_action :authorize_request

  def search_info
    items = FinderService.call(item_params[:property][:zip_code])
    path = File.join(Rails.root, "app", "assets", "templates", "plan_free_template.odt")

    download_url = ReportGeneratorService.call(path, items)

    render json: download_url, status: :ok
  end

  private

  def item_params
    params.permit(
      :customer_name,
      property: [
        :zip_code,
        :address,
        :address_number,
        :state,
        :city,
        :extra_info
      ],
      related_addresses: [
        :zip_code,
        :address,
        :address_number,
        :state,
        :city,
        :extra_info
      ]
    )
  end
end
