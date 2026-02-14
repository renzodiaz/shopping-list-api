module Api::V1
  class HouseholdsController < BaseController
    include HouseholdAuthorizable

    before_action :set_household, only: %i[show update destroy]
    before_action :authorize_member!, only: %i[show]
    before_action :authorize_owner!, only: %i[update destroy]

    def index
      households = current_user.households.includes(:owner, :household_members)
      serialize(households, serializer: HouseholdSerializer, options: serializer_options)
    end

    def show
      serialize(@household, serializer: HouseholdSerializer, options: serializer_options)
    end

    def create
      if current_user.owned_household.present?
        return render json: {
          errors: [{ status: "422", title: "Unprocessable Entity", detail: "You already own a household" }]
        }, status: :unprocessable_entity
      end

      household = Household.new(household_params)

      Household.transaction do
        household.save!
        HouseholdMember.create!(user: current_user, household: household, role: :owner)
      end

      serialize(household, serializer: HouseholdSerializer, status: :created, options: serializer_options)
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: format_errors(e.record.errors) }, status: :unprocessable_entity
    end

    def update
      if @household.update(household_params)
        serialize(@household, serializer: HouseholdSerializer, options: serializer_options)
      else
        unprocessable_entity!(@household)
      end
    end

    def destroy
      @household.destroy
      head :no_content
    end

    private

    def set_household
      @household = Household.find(params[:id])
    end

    def household_params
      params.require(:household).permit(:name)
    end

    def serializer_options
      { params: { current_user: current_user }, include: [:owner] }
    end
  end
end
