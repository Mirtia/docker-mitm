# Man in the Middle Docker Demo

This is a really simple demo to showcase a Man in the Middle (MitM) attack via ARP poisoning using Docker containers.

The idea is that this example should be really quick to set-up and lightweight: the only software required is `docker`, everything else is managed by the container's configuration. The only thing that remains is to run the attack itself.

This small demo was used in the context of [Olicyber.IT](http://olicyber.it), for the Network Security lesson.

The tools used are [mitmproxy](http://mitmproxy.org), [arpspoof](https://www.monkey.org/~dugsong/dsniff/) and [Docker](http://www.docker.com)

## Setup

There are 3 containers, Bob, Alice and Eve.

- **Bob**: is hosting an http server, serving the files contained in `bob_files`
- **Alice**: is a container with Firefox running on it. To connect to firefox from the host, visit `http://localhost:5800`.
- **Eve**: is a container meant to be used via bash. To run commands, just run `docker exec -it mitm_eve /bin/bash`. This container has the `eve_files` folder mounted on the container as `/olicyber`

The three containers are connected together with a docker bridge network called `mitm`

## How to run the demo

1. Install Docker, docker-compose, then run `docker-compose up -d`
2. Connect to Alice's Firefox instance and visit `http://bob/`. This should show the actual website served by Bob
3. You may also connect to alice via command line (`docker exec -it mitm_alice /bin/sh`) and see which MAC address corresponds to Bob's IP address (`arp`)
4. Open at least two instances of bash on Eve's container  via command line (`docker exec -it mitm_eve /bin/bash`) or, equivalently, use tmux (available in the container) and run the `dig` command to discover the IPs of Alice and Bob:

```sh
dig alice
dig bob
```

5. With this information, now run arspoof twice, once for each bash instance.

In the first bash window:
```sh
arpspoof -t <alice_ip> <bob_ip>
```

In the second bash window:
```sh
arpspoof -t <bob_ip> <alice_ip>
```

The `arpspoof` need to run continuously while performing the attack since the ARP cache entries eventually go back to their original state.
You can use `tmux` to create a new session and split the panes with shortcuts `CTRL+B` and `%` (vertical split)  or `"` (horizontal split). To detach, use `CTRL+B` and then `D`.
Tmux is preferrable since you can easily attach and detach the sessions whenever you want.

Else, you can initiate them with `nohup` to run them to background.
```sh
# Example run with nohup
nohup arpspoof -t <bob_ip> <alice_ip> &
# For multiple nohup redirect stderr and stdout of the processes to different files
# nohup arpspoof -t <bob_ip> <alice_ip> > bob_alice.log 2>&1 &
# nohup arpspoof -t <alice_ip> <bob_ip> > alice_bob.log 2>&1 &
# See list of jobs
jobs
# Bring back to foreground
fg %<job_number>
```

6. Now you may verify in Alice's `sh` instance that `ip neigh` shows that Bob's IP is now associated to Eve's MAC address, meaning that the ARP spoofing was successful (`arp`). In any case, reloading the page still shows the normal website, since Eve is not blocking any packets yet.
7. Now run the `add_iptables_rule.sh` script in the `olicyber` folder. This will add a rule to `iptables` to forward every packet with destination port 80 to the proxy
8. You may verify that Alice's browser will give an error when reloading the page. This is because Eve is not blocking the packets in pitables and forwarding them to the proxy. Since the proxy is not active yet, the packets are simply dropped.
9. Now we activate the proxy in passive mode:

```sh
mitmproxy -m transparent
```

10. Reload the browser page: the honest page will show again, but mitmproxy will show that the request passed through Eve
11. Now shut down the proxy and activate it again, this time with the script that modifies the contents of the page:

```sh
mitmproxy -m transparent -s /olicyber/proxy.py
```

12. Reload the browser page: the attacker has changed the contents of the website.
13. To shut down everything use the `del_iptables_rul.sh` script in the `olicyber` folder to remove the iptables rule and turn off the two arpspoof instances

