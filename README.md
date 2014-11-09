Hot Potato
==========

Run in three or more (minimum 2) terminals with different names:

    $ iex --name w1@127.0.0.1 -S mix
    $ iex --name w2@127.0.0.1 -S mix
    $ iex --name w3@127.0.0.1 -S mix

In each terminal, import the module and connect to other nodes:

    iex> import HotPotato.PotatoWorker; Node.connect :"w1@127.0.0.1"

In any terminal, tell the leader to start the hot potato!

    iex> start

Be sure to replace `localhost` with the IP address or host name of the node in the cluster. Also, make sure to supply unique names within the entire cluster or the application will fail to start.
