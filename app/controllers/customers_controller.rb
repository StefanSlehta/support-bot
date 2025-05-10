class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.all
  end

  def show; end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)

    if @customer.save
      sync_customer_database
      redirect_to customers_path, notice: 'Customer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    handle_sync_error(e)
  end

  def edit; end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: 'Customer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: 'Customer was successfully removed.'
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :connection_string)
  end

  def sync_customer_database
    BotpressSyncService.new(@customer).sync_database
  end

  def handle_sync_error(error)
    @customer.destroy
    render json: { error: error.message }, status: :unprocessable_entity
  end
end 