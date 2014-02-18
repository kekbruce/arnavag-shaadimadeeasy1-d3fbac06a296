class UserDetail < ActiveRecord::Base
  belongs_to :user


  # Create an entry in user table for new subscription
  #
  # <b>Expects</b>
  # * <b>params[:user_id]</b>  <em>(Integer)</em> - User id
  # * <b>params[:mobile]</b>  <em>(String)</em> - Mobile no.
  # * <b>params[:city]</b>  <em>(String)</em> - City
  #
  # <b>Returns</b>
  # * Hash[:err]: Error code, if any error
  # * Hash[:user_details]: User details record. Else nil.
  #
  # <b>Errors</b>
  # * <tt>err1</tt>: Please provide the mandatory values
  #
  def self.add_user(params)
    return {err: 'err1', :user_details => nil} if params[:user_id].to_i < 1
    user_details = create!(:user_id => params[:user_id], :mobile => params[:mobile],
                           :city => (params[:city].present? ? params[:city] : ''))
    return {err:(user_details.nil? ? 'err2' : nil), :user_details => user_details }
  end

  # attr_accessible :title, :body
end
