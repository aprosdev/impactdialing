require 'rails_helper'

describe 'DoNotCall::PortedList' do
  def r10
    s = ''
    10.times{ s << "#{rand(9)}" }
    s
  end

  let(:parser) do
    instance_double('DoNotCall::FileParser')
  end
  let(:file) do
    double('FakeFile')
  end

  subject{ DoNotCall::PortedList }

  before do
    stub_const('DoNotCall::FileParser', Class.new)
    allow(DoNotCall::FileParser).to receive(:new){ parser }
  end

  it 'caches a set of 10 digit phone numbers namespaced to given key part' do
    to_yield = [r10,r10,r10,r10,r10]
    expect(parser).to receive(:in_batches).and_yield(to_yield)
    list = subject.cache(:wireless, file)
    expect(redis.scard(list.key)).to eq to_yield.size
  end

  it 'does not retain data between calls to cache' do
    pre_exist = [r10,r10,r10]
    expect(parser).to receive(:in_batches).and_yield(pre_exist)
    list = subject.cache(:wireless, file)

    fresh = [r10,r10,r10,r10]
    expect(parser).to receive(:in_batches).and_yield(fresh)
    subject.cache(:wireless, file)
    expect(redis.scard(list.key)).to eq fresh.size
    expect(redis.smembers(list.key)).to match_array fresh.flatten
  end

  it 'creates an instance of itself scoped to the given namespace passed to .new' do
    namespace = :monkey_tails
    list = subject.new(namespace)
    expect( list.key ).to eq "do_not_call:ported:#{namespace}"
  end

  it 'checks for member existence from the last 10 digits of a phone number' do
    to_yield = [r10,r10,r10,r10,r10]
    expect(parser).to receive(:in_batches).and_yield(to_yield)
    list = subject.cache(:wireless, file)

    existing_phone = "1#{to_yield.first}"
    expect( list.exists?(existing_phone) ).to be_truthy
    expect( list.exists?(r10) ).to be_falsy
  end
end
