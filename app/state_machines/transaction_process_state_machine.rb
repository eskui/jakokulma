class TransactionProcessStateMachine
  include Statesman::Machine

  state :not_started, initial: true
  state :free
  state :initiated
  state :pending  # Deprecated
  state :preauthorized
  state :pending_ext
  state :accepted # Deprecated
  state :rejected
  state :errored
  state :paid
  state :confirmed
  state :canceled

  transition from: :not_started,               to: [:free, :initiated]
  transition from: :initiated,                 to: [:preauthorized]
  transition from: :preauthorized,             to: [:paid, :rejected, :pending_ext, :errored]
  transition from: :pending_ext,               to: [:paid, :rejected]
  transition from: :paid,                      to: [:confirmed, :canceled]

  after_transition(to: :paid) do |transaction|
    payer = transaction.starter
    current_community = transaction.community

    if transaction.booking.present?
      release_at = transaction.booking.start_on + 5.day
      Delayed::Job.enqueue(ReleaseRentalAmountToOwnerJob.new(transaction.id), run_at: release_at, priority: 5)
      automatic_booking_confirmation_at = transaction.booking.end_on + 2.day
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_booking_confirmation_at!(automatic_booking_confirmation_at)
    else
      Delayed::Job.enqueue(ReleaseRentalAmountToOwnerJob.new(transaction.id), priority: 5)
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_confirmation!
    end

    # Delayed::Job.enqueue(SendPaymentReceipts.new(transaction.id))
  end

  after_transition(to: :rejected) do |transaction|
    rejecter = transaction.listing.author
    current_community = transaction.community

    Delayed::Job.enqueue(TransactionStatusChangedJob.new(transaction.id, rejecter.id, current_community.id))
  end

  after_transition(to: :confirmed) do |conversation|
    confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
    confirmation.confirm!
  end

  after_transition(from: :paid, to: :canceled) do |conversation|
    confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
    confirmation.cancel!
  end

end
