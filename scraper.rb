#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    noko.xpath('.//h2[contains(.," Milli Məclisinin ")]//following-sibling::dl/dd').map do |dd|
      fragment dd => MemberRow
    end
  end
end

class MemberRow < Scraped::HTML
  field :name do
    return unless links[1]
    links[1].text
  end

  field :wikidata do
    links[1].attr('wikidata')
  end

  field :wikiname do
    links[1].attr('title')
  end

  field :area do
    area_data.last.tidy
  end

  field :area_id do
    area_data.first
  end

  field :party do
    party_data.first.tidy
  end

  field :party_id do
    party_data.last
  end

  private

  def links
    noko.css('a')
  end

  def place
    links.first.text
  end

  def area_data
    place.match(/(\d+) saylı (.*)/).captures
  end

  def party_data
    return [ links[2].attr('title'), links[2].text ] if links[2]
    return [ 'Independent', 'IND' ]
  end
end

def scrape_list(term, rawurl)
  url = URI.escape(URI.unescape(rawurl))
  data = MembersPage.new(response: Scraped::Request.new(url: url).response).members.reject { |m| m.name.nil? }.map do |mem|
    mem.to_h.merge(term: term)
  end
  data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite(%i[name term], data)
end

scrape_list('4', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(IV_çağırış)')
scrape_list('5', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(V_çağırış)')
