
class Util
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'
  require 'nokogiri'
  require 'securerandom'
  require 'digest/md5'

  @@logger = ActiveRecord::Base.logger


  # Validate email address format
  #
  # Author:: Arnav
  # Date:: 01/02/2014
  #
  # <b>Expects</b>
  # * <b>email_address</b> <em>(String)</em> - Email address to validate
  #
  # <b>Returns</b>
  # * <b>Boolean</b> <em>(boolean)</em> - true/false for email
  #
  def self.is_valid_email?(email_address)
    return false if email_address.blank?
    email_address_regex = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    return email_address.match(email_address_regex).nil? ? false : true
  end



  # Validate username format
  #
  # Author::Arnav
  # Date:: 01/02/2014
  #
  # <b>Expects</b>
  # * <b>username</b> <em>(String)</em> - username
  #
  # <b>Returns</b>
  # * <b>Boolean</b> <em>(boolean)</em> - true/false for email
  #
  def self.is_valid_username?(username)
    return false if username.blank? or !(3..15).include?(username.length)
    username_regex = /\A[a-z]+([a-z0-9]|_)*\Z/i
    (username.match(username_regex).nil?) ? false : true
  end


  def self.send_email(params)
    # We'll be puting up the logic as per the params to send the mail.
    # Need to check the client which should be used and the corresponding APIs
  end

  # BELOW methods are used in application, calls set, get or clear functions of memcahced.
  # Set memcached key
  #
  # <b>Excepts</b>
  # * <b>key</b> <em>(String)</em> - memcache key name.
  # * <b>data</b> <em>(Object/String/Integer)</em> - data need to be stored in memcached
  # * <b>time_of_cache</b> <em>(Integer)</em> - memcache key expiry time in seconds
  # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
  #
  def self.set_memcached(key, data, time_of_cache, marshaling)
    Timeout::timeout(1) {
      ShaadiMadeEasy::Application.config.memcached_object.set(Digest::MD5.hexdigest(key), data, time_of_cache.to_i, marshaling)
      return nil
    }
  rescue Exception => exc
    @@logger.error "MEMCACHE-ERROR: set_memcached. M : #{exc.message}, I : #{exc.inspect}"
    return nil
  end



  # Sets key if not already set. If key is already set then won't set it. returns true/false respectivly.
  #
  # <b>Excepts</b>
  # * <b>key</b> <em>(String)</em> - memcache key name.
  # * <b>data</b> <em>(Object/String/Integer)</em> - data need to be stored in memcached
  # * <b>time_of_cache</b> <em>(Integer)</em> - memcache key expiry time in seconds
  # * <b>marshaling</b> <em>(Enum)</em> - Marshal data or not?
  #
  def self.add_memcached?(key, data, time_of_cache, marshaling)
    Timeout::timeout(1) {
      # adds a memcache key if not already set. if the key exists then raises an exception.
      ShaadiMadeEasy::Application.config.memcached_object.add(Digest::MD5.hexdigest(key), data, time_of_cache.to_i, marshaling)
      return true
    }
  rescue Exception => exc
    @@logger.error "MEMCACHE-ERROR: add_memcached. M : #{exc.message}, I : #{exc.inspect}"
    return false
  end

  # Get memcached key
  #
  # <b>Excepts</b>
  # * params[:key] <em>(String)</em> - memcache key name.
  # * params[:marshaling] <em>(Enum)</em> - Marshal data or not?
  #
  def self.get_memcached(key, marshaling)
    @@logger.info "====Memcache Key===#{key.inspect}"
    Timeout::timeout(1) {
      return ShaadiMadeEasy::Application.config.memcached_object.get(Digest::MD5.hexdigest(key), marshaling)
    }
  rescue Exception => exc
    @@logger.error "MEMCACHE-ERROR: get_memcached. M : #{exc.message}, I : #{exc.inspect}" if exc.class.to_s != "Memcached::NotFound"
    return nil
  end

  # Delete memcached key
  #
  # <b>Excepts</b>
  # * params[:key] <em>(String)</em> - memcache key name.
  #
  def self.delete_memcached(key)
    Timeout::timeout(1) {
      ShaadiMadeEasy::Application.config.memcached_object.delete(Digest::MD5.hexdigest(key))
      return nil
    }
  rescue Exception => exc
    @@logger.error "MEMCACHE-ERROR: delete_memcached :" + exc.message if exc.class.to_s != "Memcached::NotFound"
    return nil
  end


  def get_hour_based_memcache_duration(time = Time.now)
    cache_duration = time.end_of_hour.to_i - time.to_i
    return cache_duration if cache_duration > 0
    1
  end


end