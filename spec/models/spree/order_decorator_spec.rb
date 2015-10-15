require 'spec_helper'

describe Spree::Order, type: :model do

  it { should have_one :avalara_transaction }

  let(:order_with_line_items) {FactoryGirl.create(:order_with_line_items)}
  let(:variant) { create(:variant) }

  before :each do
    MyConfigPreferences.set_preferences
    stock_location = FactoryGirl.create(:stock_location)
    @order = FactoryGirl.create(:order)
    line_item = FactoryGirl.create(:line_item)
    line_item.tax_category.update_attributes(name: "Clothing", description: "PC030000")
    @order.line_items << line_item
    to_address = Spree::Address.create(firstname: "Allison", lastname: "Reilly", address1: "220 Paul W Bryant Dr", city: "Tuscaloosa", zipcode: "35401", phone: "9733492462", state_name: "Alabama", state_id: 39, country_id: 1)
    @order.update_attributes(ship_address: to_address, bill_address: to_address)
  end

  describe "#avalara_eligible" do
    it "should return true" do
      expect(@order.avalara_eligible).to eq(true)
    end
  end

  describe "#avalara_lookup" do
    it "should return lookup_avatax" do
      expect(@order.avalara_lookup).to eq(:lookup_avatax)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_lookup}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#cancel_avalara" do
    let(:completed_order) {create(:completed_order_with_totals)}

    before do
      completed_order.avalara_capture
      @response = completed_order.cancel_avalara
    end

    it 'should be successful' do
      expect(@response["ResultCode"]).to eq("Success")
    end

    it "should return hash" do
      expect(@response).to be_kind_of(Hash)
    end

    it 'should receive cancel_order when cancel_avalara is called' do
      expect(completed_order.avalara_transaction).to receive(:cancel_order)
      completed_order.cancel_avalara
    end

    context 'state machine event cancel' do
      it 'should recieve cancel_avalara when event cancel is called' do
        expect(completed_order).to receive(:cancel_avalara)
        completed_order.cancel!
      end

      it 'avalara_transaction should recieve cancel_order when event cancel is called' do
        expect(completed_order.avalara_transaction).to receive(:cancel_order)
        completed_order.cancel!
      end
    end
  end

  describe "#avalara_capture" do
    it "should response with Hash object" do
      expect(@order.avalara_capture).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe "#avalara_capture_finalize" do
    it "should response with Hash object" do
      expect(@order.avalara_capture_finalize).to be_kind_of(Hash)
    end
    it "creates new avalara_transaction" do
      expect{@order.avalara_capture_finalize}.to change{Spree::AvalaraTransaction.count}.by(1)
    end
  end

  describe '#avatax_cache_key' do
    it 'should respond with a cache key' do
      expected_response = "Spree::Order-#{@order.number}-#{@order.promo_total}"

      expect(@order.avatax_cache_key).to eq(expected_response)
    end
  end
end
