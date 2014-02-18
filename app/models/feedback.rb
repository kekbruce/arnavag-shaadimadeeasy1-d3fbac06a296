class Feedback < ActiveRecord::Base
  # attr_accessible :title, :body
  FEEDBACK_TYPE = {1 => 'Vendor Suggestion', 2 => 'Product Suggestion', 3 => 'Custom'}
  FEEDBACK_TYPE_INVERT = FEEDBACK_TYPE.invert

  class << self

    def create_feedback(params)

      return {err:'err1', err_msg: 'Please fill in all the valid fields.'} if params[:body].length < 15 || params[:email].blank? || !FEEDBACK_TYPE.has_key?(params[:type])
      begin
        Feedback.create!(body:params[:body], username: params[:name], email:params[:email], type:params[:type])
        if FEEDBACK_TYPE_INVERT[params[:type]] == 'Custom'
          message = "Thanks for the feedback, we'll surely works towards the betterment through your feedback."
        else
          message = "Your feedback is sent to our team. We'll surely be working on your feedback."
        end
        return {err:nil, message:message}
      rescue Exception => e
        return {err:'err2', message:'Unable to create your feedback, Something went wrong, we are sorry for the inconvenience.'}
      end

    end


    def get_all_feedback_by_type

    end

    def get_all_feedback

    end

  end
end
