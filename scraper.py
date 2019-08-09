# -*- coding: utf-8 -*-
# Based on https://www.data-blogger.com/2016/08/18/scraping-a-website-with-python-scrapy/
import scrapy
from scrapy.linkextractor import LinkExtractor
from scrapy.spiders import Rule, CrawlSpider
from breastcancer_scraper.items import BreastcancerScraperItem


class BreastcancerSpider(CrawlSpider):
    # The name of the spider
    name = "breastcancer"

    # The domains we want to look in and which we allow the spider to go
    allowed_domains = ['cancer.gov', 'cancer.org'] #['aabcainc.org', 'aabcp.org', 'alamobreastcancer.org', 'bcagmc.org', 'bcff.org', 'beyondpinkteam.org', 'bghp.org', 'breast-cancer.adelphi.edu', 'breastcanceralliance.org', 'breastcancercare.org', 'breastcancerfocus.org', 'celebratinglife.org', 'greatneckbcc.org', 'keep-a-breast.org', 'komengreaterpennsylvania.org', 'latinascontracancer.org', 'linksforlife.org', 'mbcc.org/breast-cancer-prevention', 'mnbcc.org', 'nysbcsen.org', 'pink-link.org', 'pinkpursuit.org', 'southjerseybcc.org', 'stupidcancer.org', 'woc4me.org', 'komen.org', 'abcf.org', 'babcn.org', 'bcnwny.org', 'breastcancer.org', 'breastcancerdeadline2020.org', 'breastcanceroptions.org', 'breastcancerri.org', 'breastinvestigators.com', 'cancer.org/cancer/breast-cancer', 'circulodevida.org', 'cwcshh.org', 'debreastcancer.org', 'facingourrisk.org', 'gabcc.org', 'imaginis.com', 'komen-houston.org', 'lbbc.org', 'longbeachbcc.com', 'manhassetbreastcancer.org', 'mbcn.org', 'menagainstbreastcancer.org', 'mothersdaughters.org', 'mybreastcancersupport.org', 'nationalbreastcancer.org', 'nhbcc.org', 'sistersnetworkinc.org', 'sistersnetworkinc.org', 'sisterssurviving.org', 'slbcc.org', 'tbcc.org', 'vailbreastcancerawareness.org', 'verabradley.org', 'wibcc.org', 'wibreastcancer.org', 'womenscanceradvocacy.net', 'zerobreastcancer.org', 'komencentralva.org', 'preventcancer.org', 'sharsheret.org', 'thepinkandtheblack.org', 'tnbcfoundation.org', 'bcpp.org', 'bcrf.org', 'bhctexas.org', 'cancer.gov/types/breast', 'drsusanloveresearch.org', 'floridabreastcancer.org', 'ibcsupport.org', 'mbcalliance.org', 'mibcc.org', 'nwhn.org', 'pabreastcancer.org', 'pinkfund.org', 'sharecancersupport.org', 'vbcf.org', 'youngsurvival.org', 'babylonbreastcancer.org', 'bcaction.org', 'bccr.org', 'bcfo.org', 'hbcac.org', 'lindacreed.org', 'mainebreastcancer.org', 'nobcc.org', 'preventionisthecure.org', 'sistersnetworkchicagochapter.org', 'sistersnetworkdallas.org', 'tigerlilyfoundation.org', 'tolife.org', 'triplesteptowardthecure.org', 'wcrc.org', 'silentspring.org', 'bcfo.org', 'mainebreastcancer.org', 'mbcc.org', 'vailbreastcancerawareness.org']
    # The URLs to start with
    start_urls = ['http://www.cancer.gov/', 'http://www.cancer.org/'] #['http://aabcainc.org/', 'http://aabcp.org/', 'http://alamobreastcancer.org/', 'http://bcagmc.org/', 'http://bcff.org/', 'http://beyondpinkteam.org/', 'http://bghp.org/', 'http://breast-cancer.adelphi.edu/', 'http://breastcanceralliance.org/', 'http://breastcancercare.org/', 'http://breastcancerfocus.org', 'http://celebratinglife.org', 'http://greatneckbcc.org/', 'http://keep-a-breast.org/', 'https://komengreaterpennsylvania.org/', 'http://latinascontracancer.org/', 'http://linksforlife.org/', 'http://mbcc.org/breast-cancer-prevention/', 'http://mnbcc.org/', 'http://nysbcsen.org/', 'http://pink-link.org/', 'http://pinkpursuit.org/', 'http://southjerseybcc.org/', 'http://stupidcancer.org/', 'http://woc4me.org/', 'http://ww5.komen.org/', 'http://www.abcf.org/', 'http://www.babcn.org/', 'http://www.bcnwny.org/', 'http://www.breastcancer.org/', 'http://www.breastcancerdeadline2020.org', 'http://www.breastcanceroptions.org', 'http://www.breastcancerri.org/', 'http://www.breastinvestigators.com/', 'https://www.cancer.org/cancer/breast-cancer', 'http://www.circulodevida.org/', 'http://www.cwcshh.org/', 'http://www.debreastcancer.org/', 'http://www.facingourrisk.org', 'http://www.gabcc.org', 'http://www.imaginis.com/', 'http://www.komen-houston.org/', 'http://www.lbbc.org/', 'http://www.longbeachbcc.com/', 'http://www.manhassetbreastcancer.org/', 'http://www.mbcn.org/', 'http://www.menagainstbreastcancer.org/', 'http://www.mothersdaughters.org/', 'http://www.mybreastcancersupport.org', 'http://www.nationalbreastcancer.org/', 'http://www.nhbcc.org/', 'http://www.sistersnetworkinc.org/', 'http://www.sistersnetworkinc.org/', 'http://www.sisterssurviving.org/', 'http://www.slbcc.org', 'http://www.tbcc.org/', 'http://www.vailbreastcancerawareness.org/', 'http://www.verabradley.org/', 'http://www.wibcc.org/', 'http://www.wibreastcancer.org/', 'http://www.womenscanceradvocacy.net', 'http://www.zerobreastcancer.org', 'https://komencentralva.org/', 'https://preventcancer.org/', 'https://sharsheret.org/', 'https://thepinkandtheblack.org/', 'https://tnbcfoundation.org/', 'https://www.bcpp.org/', 'https://www.bcrf.org/', 'https://www.bhctexas.org/', 'https://www.cancer.gov/types/breast', 'https://www.drsusanloveresearch.org/', 'https://www.floridabreastcancer.org/', 'https://www.ibcsupport.org/', 'https://www.mbcalliance.org/', 'https://www.mibcc.org/', 'https://www.nwhn.org/', 'https://www.pabreastcancer.org/', 'https://www.pinkfund.org/', 'https://www.sharecancersupport.org/', 'https://www.vbcf.org/', 'https://www.youngsurvival.org/', 'www.babylonbreastcancer.org/', 'www.bcaction.org/', 'www.bccr.org/', 'www.bcfo.org/', 'www.hbcac.org/', 'www.lindacreed.org/', 'www.mainebreastcancer.org', 'www.nobcc.org', 'www.preventionisthecure.org', 'www.sistersnetworkchicagochapter.org', 'www.sistersnetworkdallas.org', 'https://www.tigerlilyfoundation.org/', 'www.tolife.org/', 'http://triplesteptowardthecure.org', 'www.wcrc.org', 'https://www.silentspring.org', 'https://www.bcfo.org/', 'https://www.mainebreastcancer.org/','http://mbcc.org/breast-cancer-prevention/', 'http://www.vailbreastcancerawareness.org/']

    # This spider has one rule: extract all (unique and canonicalized) links, follow them and parse them using the parse_items method
    rules = [
        Rule(
            LinkExtractor(
                canonicalize=False,
                unique=True
            ),
            follow=True,
            callback="parse_items"
        )
    ]

    # Method which starts the requests by visiting all URLs specified in start_urls
    def start_requests(self):
        for url in self.start_urls:
            yield scrapy.Request(url, callback=self.parse, dont_filter=True)

    # Method for parsing items
    def parse_items(self, response):
        # The list of items that are found on the particular page
        #items = []
        # Only extract canonicalized and unique links (with respect to the current page)
        links = LinkExtractor(canonicalize=False, unique=True).extract_links(response)
        # Now go through all the found links
        for link in links:
            # Check whether the domain of the URL of the link is allowed; so whether it is in one of the allowed domains
            is_allowed = False
            for allowed_domain in self.allowed_domains:
                if allowed_domain in link.url:
                    is_allowed = True
            # If it is allowed, create a new item and add it to the list of found items
            if is_allowed:
                item = BreastcancerScraperItem()
                item['url_from'] = response.url
                yield item #items.append(item)
        # Return all the found items
        #return items
