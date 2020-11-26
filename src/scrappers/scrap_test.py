#didierdrogba,  leomessi, lanadelrey, paulpogba, mb459, mileycyrus
from insta_bot import InstagramBot

usernames = ['didierdrogba', 'leomessi', 'lanadelrey']

usernames = ['didierdrogba']

bot = InstagramBot(email='email@gmail.com', password='psw')

bot.signIn()


for user in usernames:
    print(user)

    #bot.followWithUsername(username=user)
    #bot.getUserFollowing(username=user, max=10)
    #bot.getUserInfo(username=user)
    bot.getUserPosts(username=user)

bot.closeBrowser()