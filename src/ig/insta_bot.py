#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
add descr
"""

from selenium import webdriver
import time
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

# from http_request_randomizer.requests.proxy.requestProxy import RequestProxy



class InstagramBot():
    def __init__(self, email, password, path):
        # self.proxy = RequestProxy().get_proxy_list()[0].get_address()
        # webdriver.DesiredCapabilities.CHROME['proxy']={
        #    "httpProxy":self.proxy,
        #    "ftpProxy":self.proxy,
        #    "sslProxy":self.proxy,
        #    "proxyType":"MANUAL",
        # }
        self.browser = webdriver.Chrome(path + 'chromedriver')
        self.email = email
        self.password = password

    def signIn(self):
        self.browser.get('https://www.instagram.com')

        # Accept cookies
        WebDriverWait(self.browser, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[text()='Accept']"))).click()

        # Insert username and pw
        WebDriverWait(self.browser, 10).until(EC.presence_of_element_located((By.NAME, "username"))).send_keys(
            self.email)
        WebDriverWait(self.browser, 10).until(EC.presence_of_element_located((By.NAME, "password"))).send_keys(
            self.password)
        self.browser.find_element_by_name('password').send_keys(Keys.ENTER)

        # Do not save credentials
        WebDriverWait(self.browser, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[text()='Not Now']"))).click()

        # Do not enable notifications
        WebDriverWait(self.browser, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[text()='Not Now']"))).click()

    def followWithUsername(self, username):
        self.browser.get('https://www.instagram.com/' + username)
        followButton = WebDriverWait(self.browser, 10).until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button")))
        if (followButton.text in ['Segui', 'Segui anche tu', 'Follow', 'Follow Back']):
            followButton.click()
        else:
            print("You are already following this user")

    def messageWithUsername(self, username, msg):
        self.browser.get('https://www.instagram.com/' + username)
        msgButton = WebDriverWait(self.browser, 10).until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button")))
        if (msgButton.text in ['Invia un messaggio', 'Message']):
            msgButton.click()
            for i in range(0, 5):
                WebDriverWait(self.browser, 10).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "textarea"))).send_keys(msg[i])
                self.browser.find_element_by_css_selector('textarea').send_keys(Keys.ENTER)
                time.sleep(3)
        else:
            print("You do not follow this user yet")

    def checkConvStatus(self, username):
        self.browser.get('https://www.instagram.com/' + username)
        msgButton = WebDriverWait(self.browser, 10).until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button")))
        res = dict()
        if (msgButton.text in ['Invia un messaggio', 'Message']):
            msgButton.click()
            WebDriverWait(self.browser, 10).until(EC.presence_of_element_located((By.CSS_SELECTOR, "textarea")))
            html = self.browser.page_source
            pageSoup = BeautifulSoup(html, 'html.parser')
            res['user_was_contacted'] = len(pageSoup.find_all('div', {'class': 'DMBLb'})) > 0
            res['user_has_replied'] = len(pageSoup.find_all('a', {'class': '_2dbep qNELH kIKUG'})) > 0
            res['user_has_viewed'] = len(pageSoup.find_all(text='Visualizzato')) > 0
        else:
            res['user_was_contacted'] = False
            res['user_has_replied'] = False
            res['user_has_viewed'] = False
        return res

    def getUserStats(self, username):
        self.browser.get('https://www.instagram.com/' + username)
        html = self.browser.page_source
        pageSoup = BeautifulSoup(html, 'html.parser')
        user_stats_dict = {
        'user': username,
        'numberOfPosts' : str(pageSoup.find_all('span', {'class': 'g47SY'})[0].text).replace(',',''), #fix k
        'numberOfFollowers' : str(pageSoup.find_all('span', {'class': 'g47SY'})[1].text).replace(',',''),
        'numberOfFollowing' : str(pageSoup.find_all('span', {'class': 'g47SY'})[2].text).replace(',','')
        }
        for number in ['numberOfPosts','numberOfFollowers','numberOfFollowing']:
            if user_stats_dict[number].__contains__('k'):
                if user_stats_dict[number].__contains__('.'):
                    user_stats_dict[number] = user_stats_dict[number].replace('k',"00").replace('.','')
                else:
                    user_stats_dict[number] = user_stats_dict[number].replace('k',"000")

        return user_stats_dict

    def getUserFollowing(self, username, max):
        self.browser.get('https://www.instagram.com/' + username)
        html = self.browser.page_source
        pageSoup = BeautifulSoup(html, 'html.parser')
        numberOfFollowing = str(pageSoup.find_all('span', {'class': 'g47SY'})[2].text).replace('.', '').replace(',','')
        numberOfFollowingToScrape = min(max, int(numberOfFollowing))
        if numberOfFollowingToScrape > 0:
            followingLink = WebDriverWait(self.browser, 10).until(
                EC.element_to_be_clickable((By.XPATH, "//a[@href='/" + username + "/following/']")))
            followingLink.click()
            time.sleep(3)
            followingList = self.browser.find_element_by_css_selector('div[role=\'dialog\'] ul')
            numberOfFollowingInList = len(followingList.find_elements_by_css_selector('li'))
            action1 = webdriver.ActionChains(self.browser).move_to_element_with_offset(followingList, 5, 200)
            action2 = webdriver.ActionChains(self.browser)
            while (numberOfFollowingInList < numberOfFollowingToScrape):
                action1.click().perform()
                action2.key_down(Keys.SPACE).key_up(Keys.SPACE).perform()
                time.sleep(1)
                numberOfFollowingInList = len(followingList.find_elements_by_css_selector('li'))
                print(numberOfFollowingInList)
                time.sleep(1)
            following = []
            for user in followingList.find_elements_by_css_selector('li'):
                userLink = user.find_element_by_css_selector('a').get_attribute('href')
                # print(userLink)
                following.append(userLink)
                if (len(following) == numberOfFollowingToScrape):
                    break
        else:
            following = []
        print("The number of followers is {}".format(len(following)))
        return following

    def getUserInfo(self, username):
        self.browser.get('https://www.instagram.com/' + username)
        html = self.browser.page_source
        pageSoup = BeautifulSoup(html, 'html.parser')
        infoBox = pageSoup.find('div', {'class': '-vDIg'})
        info = dict()
        if infoBox.find('h1', {'class': 'rhpdm'}) is not None:
            info['name'] = infoBox.find('h1', {'class': 'rhpdm'}).text
        else:
            info['name'] = None
        if infoBox.find('a', {'class': 'yLUwa'}) is not None:
            info['website'] = infoBox.find('a', {'class': 'yLUwa'}).text
        else:
            info['website'] = None

        if infoBox.find_all('span') is not None and len(
                [s for s in infoBox.find_all('span') if not s.has_attr('class')]) > 0:
            info['bio'] = [s for s in infoBox.find_all('span') if not s.has_attr('class')][0].text
        else:
            info['bio'] = None
        return info

    def closeBrowser(self):
        self.browser.close()

    def __exit__(self, exc_type, exc_value, traceback):
        self.closeBrowser()



