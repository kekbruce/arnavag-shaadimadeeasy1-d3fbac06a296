class Category < ActiveRecord::Base
  # attr_accessible :title, :body
  # List of the wedding types present.
  #
  #
  # <b>Returns</b>
  # * Hash[:err]: Error code, if any error
  # * Hash[:suggested_items]: Array of suggested cities
  #
  # <b>Errors</b>
  # * <tt>err1</tt>: Please provide the mandatory values
  #
  def get_shaadi_types(params)
    all_result = []

    ShaadiType.all.each do |type|
      all_result << {:name => type.name,
                     :permalink =>  type.permalink,
                     :id => type.id
      }
    end
    return {:err => nil, :all_result => all_result}
  end

end
