import gspread
from oauth2client.service_account import ServiceAccountCredentials
import pandas as pd

def GSheetClient(
        gref:str,
        creds_path:str,
        gmethod: str = 'key'
):
    '''add range selecctor and sheets !=1 option'''
    gclient = gspread.service_account(filename=creds_path)

    if gmethod == 'key':
        gsheet = gclient.open_by_key(gref)
    elif gmethod == 'url':
        gsheet = gclient.open_by_url(gref)
    elif gmethod == 'name':
        gsheet = gclient.open(gref)
    else:
        print("Please provide a valid gmethod entry. \
        Accepted values are ['key','url','name'] ")

    data = gsheet.sheet1.get_all_records()

    return pd.DataFrame(data)
