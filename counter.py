#requirements
import csv
import numpy
import nltk
from nltk.corpus import stopwords
from nltk.collocations import *
import requests
from bs4 import BeautifulSoup 
import caffeine
import re
from archivenow import archivenow
                
default_stopwords = set(nltk.corpus.stopwords.words('english'))
all_stopwords = default_stopwords

keywords = {}
final_urls={}

#ancillary count functions
def count(term, visible_text): # this function counts single word terms from the decoded HTML
    term = term.lower()  # normalize so as to make result case insensitive
    tally = 0
    for section in visible_text:
    	##bigram here. instead of section.split, bigram the section
        for token in section.split():
            token = re.sub(r'[^\w\s]','',token)#remove punctuation
            tally += int(term == token.lower()) # instead of in do ==
    #print("count",term, tally)
    return tally

def two_count(term, visible_text): # this function counts two word phrases from the decoded HTML
    tally=0
    length=len(term)
    for section in visible_text:
        tokens=nltk.word_tokenize(section)
        tokens=[x.lower() for x in tokens]
        tokens=[re.sub(r'[^\w\s]','',x) for x in tokens]
        grams=nltk.ngrams(tokens,length)
        try:
            fdist=nltk.FreqDist(grams)
            tally+=fdist[term[0].lower(),term[1].lower()]
        except:
            pass
    return tally

def three_count(term, visible_text): # this function counts three word phrases from the decoded HTML
    tally=0
    length=len(term)
    for section in visible_text:
        tokens=nltk.word_tokenize(section)
        tokens=[x.lower() for x in tokens]
        tokens=[re.sub(r'[^\w\s]','',x) for x in tokens]
        grams=nltk.ngrams(tokens,length)
        try:
            fdist=nltk.FreqDist(grams)
            tally+=fdist[term[0].lower(),term[1].lower(),term[2].lower()]
        except:
            pass
    return tally

def keyword_function(visible_text):
    #based on https://www.strehle.de/tim/weblog/archives/2015/09/03/1569
    keydump=[]
    #visible_text = gvt(content)
    new_string = "".join(visible_text)
    words = nltk.word_tokenize(new_string)
    # Remove single-character tokens (mostly punctuation)
    words = [word for word in words if len(word) > 1]
    # Remove numbers
    words = [word for word in words if not word.isnumeric()]    
    # Lowercase all words (default_stopwords are lowercase too)
    words = [word.lower() for word in words]
    # Remove stopwords
    words = [word for word in words if word not in all_stopwords]
    # Calculate frequency distribution
    fdist = nltk.FreqDist(words)
    # Output top 50 words
    for word, frequency in fdist.most_common(3):
        keydump.append(word)
    #print(keydump)
    return keydump
        
def counter(file, terms):
    #counts a set of one two or three word terms during a single timeframe
    #dates should be in the following form: [starting year, starting month, starting day, ending year, ending month, ending day]
    #terms should be in the format ["term"], as a phrase: ["climate", "change"], or as a set of terms and/or phrases: ["climate", ["climate", "change"]]

    with open(file) as csvfile: 
        read = csv.reader(csvfile)
        datar = list(read)
    csvfile.close()
    
    #terms=['environmental', 'environment', 'chemical', 'chemicals', 'contaminant', 'contaminants', 'contamination', 'pollution', 'pollutants', 'pollutant', ['endocrine', 'disruptor'], ['endocrine', 'disruptors'], ['endocrine', 'disrupting', 'chemical'], ['endocrine', 'disrupting', 'chemicals'], 'prevention', 'toxic', 'toxics', 'toxin', 'toxins', 'pfoa', 'pfos', 'pfas', 'pfcs', 'pfc', ['perfluorinated', 'chemicals'], ['precautionary', 'principle'], ['hormone', 'disrupting', 'chemical'], ['hormone', 'disrupting', 'chemicals'], 'pesticide', 'pesticides', ['flame', 'retardant'], ['flame', 'retardants'], 'bpa', 'phthalates', 'phthalate', 'paraben', 'parabens', 'bisphenol', 'bisphenols', 'lead', 'oxybenzone', 'diet', 'exercise', 'genetics', ['family', 'history'], 'obese', 'overweight', ['pregnancy', 'history'], 'alcohol', ['dense', 'breasts'], ['physically', 'active'], ['oral', 'contraceptives'], ['birth', 'control'], 'des', 'diethylstilbestrol', ['hormone', 'therapy'], 'hrt', 'pah', 'pahs', ['air', 'pollution'], ['physical', 'activity'], ['breast', 'density'], 'black', ['african', 'american'], ['african', 'americans'], 'african-american', 'african-americans', 'latina', 'latinas', 'hispanic', 'latino', 'asian', 'disparity', 'disparities', 'brac1', 'brac2', 'native-american', 'native-americans', ['native', 'americans'], ['native', 'american'], 'ethnicity']
    #example use: counter(file.csv, terms) 
    
    row_count = len(data)
    column_count = len(terms)
    matrix = numpy.zeros((row_count, column_count),dtype=numpy.uint8) 
    print(row_count, column_count)
    page_sum=0 # sum of term for a specific page

    for pos, row in enumerate(data):
        url = row #or 0 depending on how the CSV is structured 
        final_urls[url]=""
        try:
            contents = requests.get(url, timeout=5).content.decode() #decode the url's HTML
            soup = BeautifulSoup(contents, 'lxml')
            d=[s.extract() for s in soup('footer')]
            d=[s.extract() for s in soup('nav')]
            d=[s.extract() for s in soup('script')]
            d=[s.extract() for s in soup('style')]
            d=[s.extract() for s in soup("div", {"id" : re.compile('nav*')})] #id includes nav (adelphi)
            d=[s.extract() for s in soup("div", {"class" : re.compile('nav*')})] 
            d=[s.extract() for s in soup.select('div.link-list')] #ACS
            d=[s.extract() for s in soup.select('div.menu-block-wrapper')] #lbbc
            d=[s.extract() for s in soup.select('div.nav-main')] #bcactionnavDiv
            d=soup.find('div',{'id': 'linkGroup'})
            del(d)
            body=soup.find('body')
            contents=[text for text in body.stripped_strings]
            #keywords[url] = keyword_function(contents)
            for p,t in enumerate(terms):
                if type(t) is list:
                    if len(t)>2:
                        page_sum=three_count(t,contents)
                    else:
                        page_sum=two_count(t,contents)
                else:
                    page_sum=count(t, contents)
                matrix[pos][p]=page_sum #put the count of the term in the matrix
            final_urls[url]=url
            print(pos)
        except:
            print("moving along ", pos)
            final_urls[url]=""
            matrix[pos]=99
    unique, counts = numpy.unique(matrix, return_counts=True)
    results = dict(zip(unique, counts))
    print (results)
    
    #for writing term count to a csv. you will need to convert delimited text to columns and replace the first column with the list of URLs

    with open('term_count_output.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=' ', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        for row in matrix:
            writer.writerow(row)
    csvfile.close()

     #print out urls in separate file
    with open('urls_output.csv','w') as output:
        writer=csv.writer(output)
        for key, value in final_urls.items():
            writer.writerow([key, value])
    output.close()

    #print out keywords in separate file
    with open('keywords_output.csv', "w", encoding='utf-8') as outfile:
        writer = csv.writer(outfile)
        for key, value in keywords.items():
            try:
                writer.writerow([key, value[0], value[1], value[2]])
            except IndexError:
                writer.writerow([key, "ERROR"])
    outfile.close()

    print("The program is finished!")
