#!/usr/bin/python
#
# Grab data from specified date range for the full set of Basis users, 
# store the data, process it, then generate reports/emails about user activities.
#
# Jeff Shrader
# Time-stamp: "2014-10-03 12:40:58 jgs"

# Feed a list of user names and passwords to the program
# TO DO:
# . Make it incrementally download in an intelligent way
# . Trash collect after stata code
# . Don't hard code paths
from dateutil import rrule
from datetime import datetime, timedelta
import csv
import os

today = datetime.now()
dir = os.path.dirname(__file__)
sd = "/Users/jgs/google_drive/research/projects/active/student_sleep/data/raw"
with open('../data/Basis Inventory - Distribution.csv', 'rb') as csvfile:
    inventory = csv.reader(csvfile)
    # Skip first two rows. First row is random password generator and second
    # row is variable headers
    next(inventory)
    next(inventory)
    # Loop over rest of rows until you reach a blank user name
    for row in inventory:
        u = row[7]
        if u != '':
            # UID is the number assigned to each user, part of their user name
            uid = u.split("@")[0].split("+")[1]
            # p is password
            p = row[8]
            # Find the active time for each user
            start = datetime.strptime(row[3], "%m/%d/%Y")
            # End time is either today or when the user returned their device
            if row[4] == '':
                end = today 
            else: 
                end = datetime.strptime(row[4], "%m/%d/%Y")

            # Run the download code over all active dates for the user
            print u
            for dt in rrule.rrule(rrule.DAILY, dtstart=start, until=end):
                dti = dt.strftime("%Y-%m-%d")
                retriever_call = "python ./BasisRetrieverv0.3/src/basis_retr.py --login_id=%s --password=%s --type=ds --date=%s --savedir=%s" % (u, p, dti, sd)
                print retriever_call
                # os.system(retriever_call)
                # Rename the file so it is unique to the user
                filename = "%s/%s_basis_sleep.csv" % (sd, dti)
                file_rename = "%s/id_%s_basis_sleep_%s.csv" % (sd, uid, dti)
                # os.rename(filename, file_rename)




# Process the data to create standardized records


# De-identify


# Combine data with existing master dataset



# Store de-identified data and archive


# Reports on weekly sleep
def sleep_report():
    report = False
    

def email_report():
    import smtplib
    
    sender = 'from@fromdomain.com'
    receivers = ['to@todomain.com']
    
    message = """From: From Person <from@fromdomain.com>
    To: To Person <to@todomain.com>
    Subject: SMTP e-mail test

    This is a test e-mail message.
    """

    try:
        smtpObj = smtplib.SMTP('localhost')
        smtpObj.sendmail(sender, receivers, message)         
        print "Successfully sent email"
    except SMTPException:
        print "Error: unable to send email"
