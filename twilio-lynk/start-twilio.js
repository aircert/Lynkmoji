var AccessToken = require('twilio').jwt.AccessToken;
var VideoGrant = AccessToken.VideoGrant;

// Substitute your Twilio AccountSid and ApiKey details
var ACCOUNT_SID = 'AC9d922a11de51daa572e03a898330950a';
var API_KEY_SID = 'SK858902c5414a660379e34a75976d43b0';
var API_KEY_SECRET = 'AyNes9Zs8S3k5Jx259lKcM3HB7VW6jIu';

const express = require('express');
const app = express();

app.get('/', (req, res) => {
  // Create an Access Token
  var accessToken = new AccessToken(
    ACCOUNT_SID,
    API_KEY_SID,
    API_KEY_SECRET
  );

  //need params for room and for identity

  // Set the Identity of this token
  accessToken.identity = req.query.User;

  // Grant access to Video
  var grant = new VideoGrant();
  grant.room = req.query.room;
  accessToken.addGrant(grant);

  // Serialize the token as a JWT
  var jwt = accessToken.toJwt();
  res.json({jwt});
});

app.listen(3000, () => console.log('Gator app listening on port 3000!'));
