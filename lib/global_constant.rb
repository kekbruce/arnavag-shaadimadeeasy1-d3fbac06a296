module GlobalConstant

  env_constants = YAML::load(open(Rails.root.to_s + '/config/constants.yml'))["constants"]

  MEMCACHE_PREFIX = env_constants["memcache"]["memcache_prefix"].freeze

  MANDRILL_API_KEY = env_constants["mandrill"]["key"].freeze
  MANDRILL_USER_NAME = env_constants["mandrill"]["username"].freeze


  # EMAIL Addresses
  CC_EMAIL = env_constants['email']['customer_care'].freeze
  INFO_EMAIL = env_constants['email']['info'].freeze
  FEEDBACK_EMAIL = env_constants['email']['feedback'].freeze
  COMPLAINT_EMAIL = env_constants['email']['complaint'].freeze
  CONTACT_EMAIL = env_constants['email']['contact'].freeze


end