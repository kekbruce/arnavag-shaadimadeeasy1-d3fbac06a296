class City < ActiveRecord::Base
  # attr_accessible :title, :body

  class << self

    # Auto-complete suggestion data for cities
    #
    #
    # <b>Excepts</b>
    # * <b>params[:q]</b> <em>(String)</em> - query string
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:suggested_items]: Hash of suggested cities
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    #
    def get_suggested_cities(params)
      return {err: 'err1', suggested_items:[]} if params[:q].blank?
      suggested_items = {}
      res_limit = params[:limit].present?? params[:limit] : 10

      City.select("id, city, region, country, permalink").where(["city LIKE ?", "#{params[:q]}%"]).limit(res_limit).each do |city|
        suggested_items << {name:city.city,permalink:city.permalink,id:city.id}
      end
      return {err:nil, count:'', total:'', suggested_items:suggested_items}
    end

    # This method will list all the cities in the database
    #
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:all_cities]: Hash of suggested cities
    #
    def list_all_cities(params)
      all_cities = {}
      City.all.each do |city|
        all_cities << {name: city.city, permalink: city.permalink, id: city.id}
      end
      return {err:nil, count:'', total:'', all_cities:all_cities}
    end

  end

end
