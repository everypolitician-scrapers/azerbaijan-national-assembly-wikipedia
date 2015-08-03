#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('.//h2[contains(.," IV ")]//following-sibling::dl/dd').each do |mp|
    links = mp.css('a')

    where = links.first.text
    area_id, area = where.match(/(\d+) saylı (.*)/).captures

    if links[2]
      party = links[2].attr('title')
      party_id = links[2].text
    else
      raise "unknown party in #{mp.text}" unless mp.text.include? 'bitərəf'
      party = "Independent"
      party_id = "IND"
    end

    data = { 
      name: links[1].text,
      wikiname: links[1].attr('title'),
      area: area.tidy,
      area_id: area_id,
      party: party,
      party_id: party_id,
      term: '4',
      source: url,
    }
    # puts data
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

scrape_list('https://az.wikipedia.org/wiki/Az%C9%99rbaycan_Respublikas%C4%B1_Milli_M%C9%99clisinin_deputatlar%C4%B1n%C4%B1n_siyah%C4%B1s%C4%B1_(IV_%C3%A7a%C4%9F%C4%B1r%C4%B1%C5%9F)')
