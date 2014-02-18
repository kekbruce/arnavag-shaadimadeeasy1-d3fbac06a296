class Product < ActiveRecord::Base
  # attr_accessible :title, :body

  class << self

    # Fetch Users the result based on the recommendations.
    #
    def fetch_recommended_products(params)
      mem_key = "#{GlobalConstant::MEMCACHE_PREFIX}pp_recommendation_details_#{params[:product_id]}"
      recommendation_details = Util.get_memcached(mem_key, true)
      if recommendation_details.blank?
        recommendation_details = get_all_products(params)
        Util.set_memcached(mem_key, recommendation_details, Util.get_hour_based_memcache_duration, true)
      end
      return recommendation_details
    end


    # Fetch all the products
    def get_all_products(params)
      where(location_id: params[:location_id], category_id: params[:category_id])

    end


    # Get all the products by a Vendor at a particular city and for a particular category
    def get_prod_from_vendor(params)
      get_all_products.where(vendor_id: params[:vender_id])
    end

  end
end
