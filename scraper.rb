#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

def noko_for(url)
  Nokogiri::HTML(open(URI.escape(URI.unescape(url))).read)
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.xpath('.//h2[contains(.," Milli Məclisinin ")]//following-sibling::dl/dd').each do |mp|
    links = mp.css('a')

    where = links.first.text
    area_id, area = where.match(/(\d+) saylı (.*)/).captures

    unless links[1]
      warn "No member for #{where} in Term #{term}"
      next
    end

    if links[2]
      party = links[2].attr('title')
      party_id = links[2].text
    else
      raise "unknown party in #{mp.text}" unless mp.text.include? 'bitərəf'
      party = 'Independent'
      party_id = 'IND'
    end

    data = {
      name:     links[1].text,
      wikiname: links[1].attr('title'),
      area:     area.tidy,
      area_id:  area_id,
      party:    party,
      party_id: party_id,
      term:     term,
    }
    puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
    ScraperWiki.save_sqlite(%i[name term], data)
  end
end

scrape_list('4', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(IV_çağırış)')
scrape_list('5', 'https://az.wikipedia.org/wiki/Azərbaycan_Respublikası_Milli_Məclisinin_deputatlarının_siyahısı_(V_çağırış)')
