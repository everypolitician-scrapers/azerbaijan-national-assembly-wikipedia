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
    noko.xpath('.//h2[contains(.,"deputatlarının")]//following::table[1]//tr[td[a]]').map do |tr|
      fragment tr => MemberRow
    end.reject(&:vacant?)
  end
end

class MemberRow < Scraped::HTML
  field :name do
    person_link.text rescue binding.pry
  end

  field :wikidata do
    person_link.attr('wikidata')
  end

  field :area do
    area_data.last.tidy
  end

  field :area_id do
    area_data.first
  end

  field :area_wikidata do
    place_link.attr('wikidata')
  end

  field :party do
    party_data[:name]
  end

  field :party_id do
    party_data[:id]
  end

  field :party_wikidata do
    party_data[:wikidata]
  end

  def vacant?
    tds[1].text.tidy.empty?
  end

  private

  def tds
    noko.css('td')
  end

  def person_link
    tds[1].at_css('a')
  end

  def place_link
    tds[4].at_css('a')
  end

  def area_data
    place_link.text.match(/(\d+) saylı (.*)/).captures
  end

  def party_link
    tds[3].css('a').last
  end

  def party_data
    return { id: 'IND', name: 'Independent', wikidata: 'Q327591' } unless party_link
    return { id: party_link.text, name: party_link.attr('title').tidy, wikidata: party_link.attr('wikidata') }
  end
end

def member_data(term, rawurl)
  url = URI.escape(URI.unescape(rawurl))
  MembersPage.new(response: Scraped::Request.new(url: url).response).members.reject { |m| m.name.nil? }.map do |mem|
    mem.to_h.merge(term: term)
  end
end

data = member_data('4', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(IV_çağırış)') +
       member_data('5', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(V_çağırış)')
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[name term], data)
