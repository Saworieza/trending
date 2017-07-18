# == Schema Information
#
# Table name: tweets
#
#  id         :integer          not null, primary key
#  text       :string
#  tweeted_at :datetime
#  metadata   :jsonb
#  address    :string
#  lat        :string
#  long       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tag_id     :integer
#

class Tweet < ApplicationRecord
  store :metadata, accessors: %i[user payload]
  reverse_geocoded_by :lat, :long
  geocoded_by         :address, :latitude  => :lat, :longitude => :long
  
  after_validation :geocode,         if: ->(obj) { obj.address.present? && obj.address_changed? }
  after_validation :reverse_geocode, if: ->(obj) { obj.lat_changed? || obj.long_changed? }
  
  belongs_to :tag

  class << self
    def create_from(tweet, tag = nil)
      new_tweet = new
      new_tweet.text = tweet.text
      new_tweet.payload = tweet.to_hash
      new_tweet.fill_address_from_(tweet)
      new_tweet.tweeted_at = tweet.created_at
      new_tweet.tag = tag
      new_tweet.save

      new_tweet
    end
  end

  def fill_address_from_(tweet)
    if tweet.geo?
      self.lat = tweet.geo.latitude
      self.long = tweet.geo.longitude
      # Address will be auto-generated by `GeoCoder`
    elsif tweet.place?
      self.address = tweet.place.full_name # Indicates full address
    else
      self.address = tweet.user.location
      # Lat, Long will be auto-generated by `GeoCoder`
    end
  end
end
