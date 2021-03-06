require 'oystercard'

describe Oystercard do

  subject(:oystercard) { described_class.new }
  let(:station) { double(:station) }
  let(:station2) { double(:station2) }
  let(:journey2) { double(:journey2, fare: 'fish') }
  let(:journey) { double(:journey, start_journey: nil, end_journey: journey2, fare: nil ) }
 
  it 'defaults with balance of 0' do
    expect(oystercard.balance).to eq 0
  end

  describe '#top_up' do
    it 'increase the balance' do
      oystercard.top_up(10)
      expect(oystercard.balance).to eq 10
    end

    it 'cannot increase the balance beyond limit' do
      message = "No more than #{Oystercard::MAX_LIMIT} in balance!"
      expect{oystercard.top_up(Oystercard::MAX_LIMIT+1)}.to raise_error message
    end
  end

  
  context 'when there is enough money for a trip' do
    before(:each) do
      oystercard.top_up(Oystercard::MAX_LIMIT)
    end

    describe '#touch_in' do
      it 'sets the start station in the journey object ' do
        expect(journey).to receive(:start_journey).with(station)
        oystercard.touch_in(station,journey)
      end
      
      it 'if card is already touched in, it calls fare on journey' do
        oystercard.touch_in(station, journey)
        expect(journey).to receive(:fare).with(oystercard)
        oystercard.touch_in(station, journey)
      end
      
      it 'if card is not already touched in it does not call fare' do
        expect(journey).not_to receive(:fare).with(oystercard)
        oystercard.touch_in(station, journey)
      end

      it 'records the journey into journey history' do
        oystercard.touch_in(station, journey)
        expect(oystercard.journey_history.last).to eq journey
      end
      
    end
    
    describe '#touch_out' do
      it 'gives last journey in journey history an end station if already touched in' do
        oystercard.touch_in(station, journey)
        expect(oystercard.journey_history.last).to receive(:end_journey).with(station2)
        oystercard.touch_out(station2)
      end
      
      it 'creates a new entry in journey_history if not touched in' do
        oystercard.touch_out(station, journey)
        expect(oystercard.journey_history.last).to eq(journey.end_journey(station))  
      end
      
      it 'last item in journey history has fare called on it' do
        oystercard.touch_in(station, journey)
        expect(oystercard.journey_history.last).to receive(:fare).with(oystercard)
        oystercard.touch_out(station, journey)
      end
      
    end
  end
  
  context "When there is less than #{Oystercard::MIN_LIMIT}" do
    it "cannot begin journey" do
      message = "insufficient funds! Need at least #{Oystercard::MIN_LIMIT}"
      expect{oystercard.touch_in(station)}.to raise_error message
    end
  end

  context '#deduct' do
    it 'reduces card balance by the amount given' do
      oystercard.top_up(20)
      expect{oystercard.deduct(5)}.to change{oystercard.balance}.by(-5)
    end
  end

end