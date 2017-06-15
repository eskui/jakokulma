module StripeService
  module Payments
    CommunityModel = ::Community

    module Command
      module_function

      Result = Struct.new(:status)

      def capture_charge(transaction_id, community_id)
        transaction = Transaction.find(transaction_id)

        if transaction.booking.present?
          if transaction.booking.start_on > Date.today
            release_at = transaction.booking.end_on
            Delayed::Job.enqueue(ReleaseRentalAmountToOwnerJob.new(transaction_id), run_at: release_at, priority: 5)
          else
            Delayed::Job.enqueue(ReleaseRentalAmountToOwnerJob.new(transaction_id), priority: 5)
          end
        else
          Delayed::Job.enqueue(ReleaseRentalAmountToOwnerJob.new(transaction_id), priority: 5)
        end

        begin
          result = Result.new
          result.status = 'succeeded'
        rescue Stripe::InvalidRequestError => e
          error = e.message
        rescue Exception => e
          error = e.message
        end

        if result and result.status == "succeeded"
          StripeLog.info("=================================================================================")
          StripeLog.info("Submitted authorized payment #{transaction_id} to settlement")
          StripeLog.info("=================================================================================")
        else
          StripeLog.error("=================================================================================")
          StripeLog.error("Could not submit authorized payment #{transaction_id} to settlement (#{error})")
          StripeLog.error("=================================================================================")
        end

        return result, error
      end

      def void_transaction(transaction_id, community_id)
        transaction = Transaction.find(transaction_id)
        community = Community.find(community_id)

        stripe_charge_id = transaction.payment.stripe_transaction_id


        Stripe.api_key = transaction.payment.payment_gateway.stripe_secret_key
        result, error = nil, nil
        begin
          ch = Stripe::Charge.retrieve(stripe_charge_id)
          result = ch.refunds.create(:reverse_transfer => true)
          # result = Stripe::Refund.create(charge: stripe_charge_id, :reverse_transfer => true)
        rescue Stripe::InvalidRequestError => e
          error = e.message
        rescue Exception => e
          error = e.message
        end

        if result and result.status == "succeeded"
          StripeLog.info("=================================================================================")
          StripeLog.info("Voided transaction #{transaction_id}")
          StripeLog.info("=================================================================================")
        else
          StripeLog.error("=================================================================================")
          StripeLog.error("Could not void transaction #{transaction_id}. #{error}")
          StripeLog.error("=================================================================================")
        end

        return result, error
      end
    end

  end
end