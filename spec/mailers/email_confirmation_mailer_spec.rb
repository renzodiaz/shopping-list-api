require "rails_helper"

RSpec.describe EmailConfirmationMailer, type: :mailer do
  describe "#confirmation_email" do
    let(:user) { create(:user, :unconfirmed) }
    let(:otp) { "123456" }
    let(:mail) { described_class.confirmation_email(user, otp) }

    it "sends to user email" do
      expect(mail.to).to eq([user.email])
    end

    it "has correct subject" do
      expect(mail.subject).to eq("Confirm your email address")
    end

    it "includes OTP in body" do
      expect(mail.body.encoded).to include(otp)
    end

    it "includes expiration time in body" do
      expect(mail.body.encoded).to include("10 minutes")
    end
  end
end
