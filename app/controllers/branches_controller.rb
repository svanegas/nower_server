class BranchesController < ApplicationController

  def index
    render json: {
      branches: Branch.all
    },
    except: [:created_at, :updated_at]
  end

  def create
    branch = Branch.new create_params
    if branch.name && branch.store_id
      already = Branch.where name: branch.name, store_id: branch.store_id
      if already.count != 0
        render json: {
          success: false,
          errors: ["Branch already exists"],
        }
        return
      end
      if !Store.find_by id: branch.store_id
        render json: {
          success: false,
          errors: ["Invalid store"]
        }
        return
      end
    end
    if branch.save
      render json: {
        success: true,
        branch: branch
      },
      except: [:created_at, :updated_at]
    else
      render json: {
        success: false,
        errors: branch.errors
      }
    end
  end

  def get_by_locations
    #branches = Branch.find_by_sql Branch.branches_without_expired_promos_query
    branches = Branch.all
    branches = branches.as_json(except: [:created_at, :updated_at])
    branches.each do |branch|
      branch["promos"] = Promo.find_by_sql(
            Promo.promos_available_by_branch_query branch["id"])
                  .as_json(except: [:created_at, :updated_at])
    end
    render json: {
      locations: branches
    },
    include: [:promos],
    methods: [:store_name]
  end

  def get_by_locations_in_range
    query = Branch.geolocation_query get_by_locations_in_range_params
    render json: {
      locations: Branch.find_by_sql(query)
    },
    only: [:locations, :id, :latitude, :longitude, :store_id, :name],
    methods: [:store_name],
    include: {
      promos: {
        only: [:promos, :id, :title, :expiration_date],
        methods: [:available_redemptions]
      }
    }
  end

  private
  def create_params
    params.require("branch").permit("name",
                                    "address",
                                    "latitude",
                                    "longitude",
                                    "phone",
                                    "store_id")
  end

  def get_by_locations_in_range_params
    params.require("user_location").permit("latitude", "longitude")
  end
end
