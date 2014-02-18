class User < ActiveRecord::Base
  # attr_accessible :title, :body
  # Require mandatory gems
  require 'digest/md5'

  # Define relationships
  has_one :user_detail
  has_many :shopping_carts
  has_many :product_reminders
  has_one :user_setting

  has_one :email_preference

  # Define attribute accessors
  cattr_accessor :current_user, :is_user_agent_bot
  attr_accessor :password
  attr_accessor :gender

  validates :username, :presence => true

  # Callback methods
  before_create :before_add_user
  after_create :after_add_user



  class << self

    # Add new user account
    #
    # <b>Expects</b>
    # * <b>params[:email]</b> <em>(String)</em> - User email
    # * params[:password] <em>(String)</em> - Password
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:user]: User Object
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Email cannot be blank
    # * <tt>err2</tt>: Password cannot be blank
    # * <tt>err3</tt>: Not a valid email address
    # * <tt>err4</tt>: User already deleted by admin
    # * <tt>err5</tt>: Email address already exists
    # * <tt>err6</tt>: Could not generate username now. Please try again.
    # * <tt>err7</tt>: User already created
    # * <tt>err8</tt>: Cannot create user record
    #
    def self.add_user(params)
      # Initialize defaults
      invitation_code_used, auto_generated_username, unique_username_attempts = nil, nil, 5

      # Check for mandatory parameters
      return {err: "err1", err_msg: "Email can't be blank"} if params[:email].blank?
      return {err: "err2", err_msg: "Password can't be blank"} if !params[:password].nil? and params[:password].blank?

      # Set default params
      params[:password] = params[:password].present? ? params[:password] : nil

      # Validate email format
      return {err: "err3", err_msg: "Not a valid email address"} unless Util.is_valid_email?(params[:email])

      # Check for the given email in deleted_users table
      return {err: "err4", err_msg: "User already deleted by Admin"} if DeletedUser.where("email = ?", params[:email]).first.present?


      # Check if email already taken or not
      return {err: "err5", err_msg: "Email address already in use"} if where(["email =?", params[:email]]).first.present?

      # Random invite code of 6 characters
      invitation_code = User.gen_invite_code(6)
      gen_ic_permalink = nil

      unique_username_attempts.times do |i|
        gen_ic_permalink = Permalink.create!(:permalink => invitation_code, :link_type => 2) rescue nil
        if gen_ic_permalink.nil?
          invitation_code = User.gen_invite_code(6)
        else
          break
        end
      end

      # Cannot generate unique invitation code at this moment. Need to try again
      return {err: "err6", err_msg: "Could not generate username now. Please try again."} if gen_ic_permalink.blank?

      # Generate auto token
      auth_token = User.encrypt(params[:email], "#{Time.now.to_i}")

      # Generate password hash
      password_hash = params[:password].present? ? User.encrypt(params[:password], auth_token) : nil

      # check if subscription invitation code exists or not
      special_viral_offer = false
      if params[:invitation_code_used].present?
        referrer_user = where("invitation_code = ?", params[:invitation_code_used]).first
        if referrer_user.present?
          # Assign the invitation code.
          invitation_code_used = params[:invitation_code_used]
          # Check if the referrer is in offer period.
          if Util.check_for_special_viral_offer(referrer_user)
            # Get marketing params
            params[:utm_params] = User.map_fref_in_utm_params(:fref => "invite-v-offer-1", :frefl => "")[:utm_params]
            # Also set the flag to send the joined user the credits.
            special_viral_offer = true
          end
        else
          invitation_code_used = nil
        end
      end
      # Set sales access time restriction
      sales_access_from = Time.now
      unique_permalink = create_permalink_for_username(params[:email], unique_username_attempts)
      auto_generated_username = unique_permalink.permalink if unique_permalink.present?

      if auto_generated_username.blank?
        #Delete created permalink
        Permalink.delete(gen_ic_permalink.id)
        # Cannot generate unique username at this moment. Need to try again
        return {err: "err6", err_msg: "Could not generate username now. Please try again."}
      end
      # Find currency based on user's ip
      user_currency_pref = StoreUtil.is_us_store? ? StoreUtil.base_currency_id :  StoreUtil.get_ip_based_currency_id(params[:remote_ip]) # rescue StoreUtil.base_currency_id
      # Create user entry
      begin
        user = create(:email => params[:email],
                      :username => auto_generated_username,
                      :password_hash => password_hash,
                      :auth => auth_token.to_s,
                      :fb_user_id => params[:fb_user_id].present? ? params[:fb_user_id] : 0,
                      :password_generated => params[:password_generated],
                      :lang_pref => params[:lang_pref],
                      :currency_pref => user_currency_pref,
                      :gender => params[:gender])

      rescue Exception => e
        #Delete created permalink
        Permalink.delete(unique_permalink.id)
        Permalink.delete(gen_ic_permalink.id)
        # Check if user got created already
        user = where("email = ?", params[:email]).first
        return {err: user.present? ? "err7" : "err8", :user => user}
      end
      #update permalink for user id.
      Permalink.update_all(["type_id=?", user.id],["id=? OR id=?", unique_permalink.id, gen_ic_permalink.id])
      return {err: nil, :user => user}

    end

    # create permalink entry for the user.
    #
    def self.create_permalink_for_username(email, attempts)
      gen_permalink = nil
      username = email.split("@").first.to_s.gsub(/[^a-z0-9_]/i, "").to_s[0..11].downcase
      username = random_password(5) if username.blank?
      temp_username = username
      (attempts+1).times do |i|
        gen_permalink = Permalink.create!(:permalink => temp_username, :link_type => 1) rescue nil
        if gen_permalink.nil?
          username = random_password(5) if i == (attempts - 1)
          temp_username = username + Util.random_number(100,999).to_s
        else
          break
        end
      end
      return gen_permalink
    end



    def self.send_welcome_mail(email)
      #need to send the welcome email to the user
    end

    # Reset password
    #
    # Author:: Arnav
    #
    # <b>Expects</b>
    # * <b>params[:pass_reset_email]</b> <em>(String)</em> - User email
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    #
    def self.reset_password(params)
      customer = User.find_by_email(params[:pass_reset_email]) if params[:pass_reset_email].present?
      return {err:"err1", :err_msg => "No such registered User"} if customer.nil?
      return {err:"err2", :uid => customer.id} if customer.username.nil?
      password_reset_token = User.encrypt(Time.now.to_i.to_s, customer.auth)
      if UserDetail.update_all(["password_reset_token = ?", password_reset_token], ["user_id = ?", customer.id]) > 0
        forgot_password_url = "#{GlobalConstant::ROOT_URL}change-password/?password_reset_token=#{password_reset_token}"
        Util.send_email(:template_name => "int_forgot_password",
                        :emails => customer.email,
                        :email_vars => {"forgot_password_url" => forgot_password_url})
        return {err:nil, forgot_password_url:forgot_password_url}
      else
        return {err:"err3"}
      end
    end


    # Authenticate user based on username or email
    #
    # <b>Expects</b>
    # * <b>params[:un_or_email]</b> <em>(String)</em> - username or email
    # * <b>params[:password]</b> <em>(String)</em> - username or email
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:user]: User Object
    def authenticate(params)
      return {err:"err1", :user => nil} if params.blank? || params[:un_or_email].blank? or params[:password].blank?
      u = User.get_user_fast(:query => params[:un_or_email]).first
      return {err:(u.nil? ? "err2" : "err3"), :user => nil} if u.nil? || u.password_hash.blank?
      # If password hash is migrated then use respective algo to authenticate and then switch password hash as per US algo
      @migrated_hash = false
        return {err:"err3", :user => nil} if password_hash.blank? ||
            (Digest::SHA256.hexdigest(params[:password])!=password_hash)
      @migrated_hash= true

      if @migrated_hash
        # Switch the password hash as per US algo
        u.password_hash = User.encrypt(params[:password], u.auth)
        User.update_all(["password_hash = ?", u.password_hash], ["id = ?", u.id])
        return {err:nil, :user => u}
      end
      # Use US algo to authenticate
      return (User.encrypt(params[:password], u.auth) == u.password_hash) ? {err:nil, :user => u} : {err:"err3", :user => nil}
    end


    # Save the changed username
    #
    # <b>Expects</b>
    # * <b>params[:username]</b> <em>(String)</em> - User's new username to be changed for user
    #
    # <b>Returns</b>
    # * Hash[:err]: Any error code. If no error, its nil
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    # * <tt>err2</tt>: Update failed because username can't have spaces, numbers at start etc
    # * <tt>err3</tt>: Update failed because username can't have spaces, numbers at start etc
    #
    def save_username(params)
      # User object and the username are must
      return {err:'err1'} if User.current_user.blank? or params[:username].blank?
      # Check if username format is valid
      return {err:'err3'} unless Util.is_valid_username?(params[:username])
      return {err:nil} if User.current_user.username == params[:username]

      # Get the customer object for current_user
      user_obj = User.current_user
      begin
        return {err:'err2'} if Permalink.update_all(["permalink=?, updated_at=?", params[:username], Time.now],["permalink=?", User.current_user.username]) == 0
        user_obj.username = params[:username]
        if user_obj.save
          return {err:nil}
        else
          return {err:'err3'}
        end
      rescue ActiceRecord::RecordNotunique
        return {err:'err2'}
      rescue Exception => e
          return {err:'err3'}
      end
    end



    # Save the changed email address
    #
    # Note - Touched during NEMS - Murtuza
    # <b>Expects</b>
    # * <b>params[:email]</b> <em>(String)</em> - User's email address
    #
    # <b>Returns</b>
    # * Hash[:err]: Any error code. If no error, its nil
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    # * <tt>err2</tt>: Invalid email
    # # * <tt>err3</tt>: Update failed
    #
    def save_email(params)
      # User object and the username are must
      return {err:"err1"} if User.current_user.blank? or params[:email].blank?
      # Check if username format is valid
      return {err:"err2"} unless Util.is_valid_email?(params[:email])
      return {err:"err4"} if Util.is_deleted_email?(params[:email])
      return {err:nil} if User.current_user.email == params[:email]
      # Get the customer object for current_user
      customer_obj = User.find_by_id(User.current_user.id)
      # Assign the new email to customer object
      customer_obj.email = params[:email]
      saved_email = false
      begin
        saved_email = customer_obj.save
      rescue ActiveRecord::RecordNotUnique
        return {err:"err3"} if (/Mysql2::Error: Duplicate entry/.match(e.to_s))
      rescue Exception => e
        return {err:"err2"}
      end
      if saved_email
        # Get user's previous email settings like variables, lists, optout etc to transfer them to the new(changed) email address
        email_sailthru_settings = Util.sailthru_get_email_details(:email => User.current_user.email)[:sailthru_response]

        # transfer old email sailthru setting to new email
        sailthru_response = Util.sailthru_set_email(:email => params[:email], :email_vars => (email_sailthru_settings["vars"]),
                                                    :list_preference_hash => (email_sailthru_settings["lists"]),
                                                    :optout => EmailPreference.get_user_email_preference.optout_type)[:sailthru_response]
        create_sailthru_transaction_on_error(sailthru_response)

        # unsubscribe user's old email
        sailthru_response = Util.sailthru_set_email(:email => User.current_user.email, :list_preference_hash => {GlobalConstant::SAILTHRU_DAILY_SALES_EMAIL_USER_LIST => 0}, :optout => "all")[:sailthru_response]
        create_sailthru_transaction_on_error(sailthru_response)

        # Set double optin = 0 for the new email
        EmailPreference.get_user_email_preference.update_attributes({:double_opt_in => 0})

        # Rutvij:: (16-08-2011)
        # Delete memcache which stores fulfillment users if current user is a fulfillment user
        if User.current_user.user_type == "fulfillment"
          # refresh memcache
          memcache_key = GlobalConstant::MEMCACHE_PREFIX+"ff_users"
          # remove memcache
          Util.delete_memcached(memcache_key)
        end
        User.current_user = customer_obj
        # Send email for confirming new email id
        User.send_double_optin_notification(:email => params[:email], :id => User.current_user.id, :email_change => 1)
        return {err:nil, :show_popup => true}
      else
        return {err:"err2"}
      end
    end


    # Get the user details by email
    #
    # <b>Expects</b>
    # * <b>params[:email]</b>  <em>(String)</em> - Email of the user
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:user]: User details
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    # * <tt>err2</tt>: Not found
    #
    def get_user_by_email(params)
      params[:email] = params[:email].strip rescue ""
      return {err: "err1", :user => nil} if params[:email].blank?
      ##NOTE: Memcache it
      user = where("email=?", params[:email]).first
      return  {err: user.present? ? nil : "err2", :user => user}
    end

    # Get the user details by email
    #
    # <b>Expects</b>
    # * <b>params[:id]</b>  <em>(Array)</em> - Array of user ids
    # * params[:select]  <em>(String)</em> - Columns from user table
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error
    # * Hash[:user]: User details
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    #
    def get_user_by_id(params)
      return {err: "err1"} if params[:ids].blank?
      params[:select] = "*" if params[:select].blank?
      select("#{params[:select]}").where(:id => params[:ids])
    end



    # Change Users password
    #
    # <b>Expects</b>
    # * <b>params[:new_password]</b> <em>(String)</em> - New Password
    # * <b>params[:conf_password]</b> <em>(String)</em> - Confirm New Password
    #   params[:old_password] <em>(String)</em> - Old Password
    #   params[:password_reset_token] <em>(String)</em> - Password Reset Token in case of Forgot Password
    #
    # <b>Returns</b>
    # * Hash[:err1]: If Old password hash does not match - Error would come only in Logged In Case
    # * Hash[:err2]: If entry is not found in UserDetails - Error would come only in Logged Out Case
    # * Hash[:err3]: If New password and Confirm password do not match
    #
    def change_password(params)

      return {err: "err1"} if params[:new_password].length < 1 || params[:conf_password].length < 1
      return {err: "err3"} if params[:new_password] != params[:conf_password]
      # Request is coming from 'change password' - Logged In Case
      if User.current_user.present?
        user_settings = UserSetting.where(:user_id => User.current_user.id).select("password_generated").first
        # Password Hash for old password parameter. Alpesh(18/06/2012): check current password only if user has generated his password.
        return {err: "err1"} if user_settings.present? and user_settings.password_generated.to_i == 1 and User.current_user.password_hash.present? and User.encrypt(params[:old_password].to_s, User.current_user.auth) != User.current_user.password_hash
        user_obj = User.current_user
        # Request is coming from 'forgot password' - Logged Out Case
      else
        user_detail_obj = UserDetail.select("id, user_id").where(["password_reset_token = ?", params[:password_reset_token]]).first if params[:password_reset_token].present?
        return {err: "err2"} if user_detail_obj.nil?
        user_obj = User.where(["id = ?",user_detail_obj.user_id]).first
        return {err: "err4"} if user_obj.blank? or user_obj.status != "active"
      end
      # Update users record with the new password hash
      new_password_hash = User.encrypt(params[:new_password].to_s, user_obj.auth)
      User.update_all(["password_hash = ?", new_password_hash],["id = ?",user_obj.id])
      user_obj.password_hash = new_password_hash
      User.current_user.password_hash = new_password_hash if User.current_user.present?
      UserDetail.update_all(["password_reset_token = NULL"],["user_id = ?",user_obj.id]) if params[:password_reset_token].present?
      UserSetting.update_all(["password_generated = 1"],["user_id = ?",user_obj.id])
      # Facebook sign up scenario not behaving as expected due to memcached data
      # Author  : Murtuza
      # Reviewer : Bala
      # Date : 21/09/2012
      user_settings_key = GlobalConstant::MEMCACHE_PREFIX+"_user_setting_#{user_obj.id}"
      Util.delete_memcached(user_settings_key)
      # return success if password updated successfully
      return {err: nil, :user => user_obj }
    end




    # Save the changed email address
    #
    # Author:: Sumatnh
    # Date:: 12/05/2011
    # Note - Touched during NEMS - Murtuza
    # <b>Expects</b>
    # * <b>params[:email]</b> <em>(String)</em> - User's email address
    #
    # <b>Returns</b>
    # * Hash[:err]: Any error code. If no error, its nil
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: Please provide the mandatory values
    # * <tt>err2</tt>: Invalid email
    # # * <tt>err3</tt>: Update failed
    #
    def save_email(params)
      # User object and the username are must
      return {err: "err1"} if User.current_user.blank? or params[:email].blank?
      # Check if username format is valid
      return {err: "err2"} unless Util.is_valid_email?(params[:email])
      return {err: "err4"} if Util.is_deleted_email?(params[:email])
      return {:err  => nil} if User.current_user.email == params[:email]
      # Get the customer object for current_user
      customer_obj = User.find_by_id(User.current_user.id)
      # Assign the new email to customer object
      customer_obj.email = params[:email]
      saved_email = false
      begin
        saved_email = customer_obj.save
      rescue Exception => e
        # Return the result
        return {err: "err3"} if (/Mysql2::Error: Duplicate entry/.match(e.to_s))
        return {err: "err2"}
      end
      if saved_email
        # Changes by Sumanth on Oct 09, 2011
        # Get user's previous email settings like variables, lists, optout etc to transfer them to the new(changed) email address
        email_sailthru_settings = Util.sailthru_get_email_details(:email => User.current_user.email)[:sailthru_response]

        # transfer old email sailthru setting to new email
        sailthru_response = Util.sailthru_set_email(:email => params[:email], :email_vars => (email_sailthru_settings["vars"]),
                                                    :list_preference_hash => (email_sailthru_settings["lists"]),
                                                    :optout => EmailPreference.get_user_email_preference.optout_type)[:sailthru_response]
        create_sailthru_transaction_on_error(sailthru_response)

        # unsubscribe user's old email
        sailthru_response = Util.sailthru_set_email(:email => User.current_user.email, :list_preference_hash => {GlobalConstant::SAILTHRU_DAILY_SALES_EMAIL_USER_LIST => 0}, :optout => "all")[:sailthru_response]
        create_sailthru_transaction_on_error(sailthru_response)

        # Set double optin = 0 for the new email
        EmailPreference.get_user_email_preference.update_attributes({:double_opt_in => 0})

        # Rutvij:: (16-08-2011)
        # Delete memcache which stores fulfillment users if current user is a fulfillment user
        if User.current_user.user_type == "fulfillment"
          # refresh memcache
          memcache_key = GlobalConstant::MEMCACHE_PREFIX+"ff_users"
          # remove memcache
          Util.delete_memcached(memcache_key)
        end
        User.current_user = customer_obj
        # Send email for confirming new email id
        User.send_double_optin_notification(:email => params[:email], :id => User.current_user.id, :email_change => 1)
        return {err: nil, show_popup:true}
      else
        return {err: "err2"}
      end
    end



    # Try to log in user using facebook credentials
    #
    # <b>Parameters</b>
    # * <b>params[:user][:fb_id]</b> <em>(Integer)</em> - User FaceBook ID
    # * params[:user][:fb_email] <em>(String)</em> - User FaceBook Email that received in request params
    #
    # <b>Returns</b>
    # * Hash[:err]: Error code, if any error. Else nil.
    # * Hash[:scenario]: In which scenario user falling in 1-existing fb id, 2-fb id not present and email matches in system, 3-fb id and email both not match.
    # * Hash[:user]: User table object
    # * Hash[:form_type]: If Error comes, which form to be loaded.
    #
    # <b>Errors</b>
    # * <tt>err1</tt>: mandatory params missing.
    # * <tt>fberr1</tt>: when fb email is maching with fab email, but fab email id already associated with anorher fb account.
    # * <tt>reauth_error1</tt>: when fb email is maching with fab email, but fab email id already associated with anorher fb account.
    #
    def fb_connect(params)
      return {err:"err1"} if params[:user].blank? or params[:user][:fb_id].blank?
      fb_id = params[:user][:fb_id].to_i
      fb_email = params[:user][:fb_email]
      user = User.where(fb_user_id:fb_id).first
      proceed = User.current_user.blank? ? true : (User.current_user == user)
      if proceed
        if user.present?
          return{err:nil, scenario:1, user:user, form_type:"login"}
        elsif StoreUtil.is_eu_store?  #Fab EU Shut Down condition. By default new user fb connect is blocked.
          return {err:"reauth_error1", :scenario => 4}
        else
          user_in_perm_table = PermFbFabId.where(fb_user_id:fb_id).first
          if user_in_perm_table.present?
            user = find(user_in_perm_table.user_id)
            return {err:nil, scenario:1.1, user:user, form_type:"login"}
          end
          user = User.where(email:fb_email).first
          if user.blank?
            return {err:nil, scenario:3}
          elsif user.fb_user_id == 0
            return{err:nil, scenario:2, user:user}
          else
            return {err:"fberr1"}
          end
        end
      end
      return {err:"reauth_error1"}
    end

  end

  def after_add_user
    UserDetail.add_user(user_id:self.id, mobile:self.mobile, city:self.city)
    # TODO: Sebd Welcome Mail
  end

end
