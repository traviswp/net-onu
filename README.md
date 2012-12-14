###README
----------------------------------------------------------------
######Author: Travis W. Peters
######School: Western Washington University
######Date  : December 2012
----------------------------------------------------------------

net-onu (<-- backwards spelling)

  A networked implementation of the game "UNO".

The two main entry points are:

    `server`
    `client`

but the bulk of the functionality take place in the following classes:

    `ClientClass.rb`
    `ServerClass.rb`

Both the client and server had specific messages they had to handle/send.
The following classes helped me handle this portion of the project:

    `ClientMsg.rb`
    `ServerMsg.rb`
    
Message passing standards were set by our class and I made the following
classes to handle the construction of properly formatted messaging. As
the project went on I actually put some of the message validation logic
within the Client/Server classes - I will get around to refactoring this
out and putting it into these messaging classes (where it makes more sense
to have validation).

The supplementary game object classes are:
    
    `Card.rb`
    `Deck.rb`
    `PlayerClass.rb`
    `PlayerList.rb`
    
There is also a shared module which a hand full of these classes
use in order to reduce redundancy:

    `Constants.rb`

Some additional (fun) scripts that I wrote for this product are:

    `spawn.rb`
    `log_flush.rb'

The `spawn.rb` script can:

    - spin up an instance of the server
    - spin up an instance of a manual client
    - spin up a to-be-determined number of clients (5 by default)

By default the server will run on localhost & the clients will connect to 
that instance of the server. If no server is started with this script, you
can specify the host and port that you would like the auto/manual clients to
connect to. 

Log files for each of the players (and the server if you are running that
locally) will be generated in the "logs" directory at the base level of
the project. The `log_flush.rb` script was just something fun that I made
to clear out that directory before committing my project to source control
(yes I am aware I could have done this with the .gitignore file - but making
Ruby scripts are much more fun!) :)

The plan is to get around to making a GUI for the game sometime soon to make
the game more fun so be on the look out for that!

Enjoy!

----------------------------------------------------------------

A useful command for cleaning up your local repository:

git ls-files --deleted -z | xargs -0 git rm

----------------------------------------------------------------

