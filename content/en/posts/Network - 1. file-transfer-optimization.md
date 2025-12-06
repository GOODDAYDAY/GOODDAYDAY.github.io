+++
date = '2025-09-21T16:11:17+08:00'
draft = false
title = '[Network] 1. File Transfer Optimization Sharing'
categories = ["network"]
tags = ["network", "tcpdump"]
+++

## Background (Sensitive Data Masked)

- Due to various requirements, we need to upload data to overseas OSS for storage. So we developed a proxy service to maintain data and perform encryption operations. During this process, we discovered that data upload and download were very slow. After a series of investigations, we finally located the root cause of the problem and provided a solution. We're now sharing the troubleshooting process.
- Of course, one prerequisite is `internal network connectivity through dedicated line network access` to achieve theoretical physical limits. Using complex and lengthy public networks is neither suitable for file security nor for large file long-term transmission.

## Service-Level Issues

<img src="/images/2.%20%E6%96%87%E4%BB%B6%E4%BC%A0%E8%BE%93%E4%BC%98%E5%8C%96%E5%88%86%E4%BA%AB/sequence-1-.svg" alt="Description" style="width: 600px; height: auto;" />

- Initially, we suspected it was due to data writing to disk being too slow. Because uploads must be written to disk to prevent files from being too large. Downloads use direct streaming transmission, which is very reasonable. The only improvement would be to perform streaming encryption and transmission for uploads, but the current issue is not significant.

## Phenomenon

- Using our written script to upload 1M of encrypted data took nearly 2 seconds

```python
import requests
requests.post(f"{url}/upload/files", files={
    "data": ('', upload_data, "application/json"),
    "file": transfer_data
})
```

```bash
$ python oss.py --file_input=./1M.data --region=us --model=3 --range=5
encrypted_upload
upload ./1M.data, encrypt cost 4.714599609375, upload cost 1788.95849609375
upload ./1M.data, encrypt cost 10.140625, upload cost 1945.90087890625
upload ./1M.data, encrypt cost 9.924560546875, upload cost 1756.984130859375
upload ./1M.data, encrypt cost 8.694580078125, upload cost 1930.31201171875
upload ./1M.data, encrypt cost 8.279296875, upload cost 1739.38623046875
```

## Packet Capture

- After communicating with operations, they suspected it was a network issue and performed packet capture to investigate.

### Packet Capture Demonstration

#### Ping Packets

```bash
$ sudo tcpdump -i bond0 | grep x.x.x.x1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on bond0, link-type EN10MB (Ethernet), capture size 262144 bytes
16:21:19.255718 IP public2.alidns.com.domain > domain1.36590: 43190 1/0/1 A x.x.x.x1 (88)
16:21:19.256404 IP domain1 > x.x.x.x1: ICMP echo request, id 32590, seq 1, length 64
16:21:19.456754 IP x.x.x.x1 > domain1: ICMP echo reply, id 32590, seq 1, length 64
16:21:20.257688 IP domain1 > x.x.x.x1: ICMP echo request, id 32590, seq 2, length 64
16:21:20.458076 IP x.x.x.x1 > domain1: ICMP echo reply, id 32590, seq 2, length 64
16:21:21.259088 IP domain1 > x.x.x.x1: ICMP echo request, id 32590, seq 3, length 64
16:21:21.459506 IP x.x.x.x1 > domain1: ICMP echo reply, id 32590, seq 3, length 64
16:21:22.260538 IP domain1 > x.x.x.x1: ICMP echo request, id 32590, seq 4, length 64
16:21:22.460976 IP x.x.x.x1 > domain1: ICMP echo reply, id 32590, seq 4, length 64
```

```bash
$ ping domain1
PING domain1 (x.x.x.x1) 56(84) bytes of data.
64 bytes from x.x.x.x1 (x.x.x.x1): icmp_seq=1 ttl=58 time=200 ms
64 bytes from x.x.x.x1 (x.x.x.x1): icmp_seq=2 ttl=58 time=200 ms
64 bytes from x.x.x.x1 (x.x.x.x1): icmp_seq=3 ttl=58 time=200 ms
^C
--- domain1 ping statistics ---
4 packets transmitted, 3 received, 25% packet loss, time 3004ms
rtt min/avg/max/mdev = 200.395/200.419/200.456/0.517 ms
```

#### Three-Way Handshake

```bash
16:54:06.286416 IP domain1.33666 > x.x.x.x1.http: Flags [S], seq 2682796272, win 64240, options [mss 1460,sackOK,TS val 2595135963 ecr 0,nop,wscale 7], length 0
16:54:06.486797 IP x.x.x.x1.http > domain1.33666: Flags [S.], seq 2198055866, ack 2682796273, win 62643, options [mss 1460,sackOK,TS val 2062390218 ecr 2595135963,nop,wscale 7], length 0
16:54:06.486840 IP domain1.33666 > x.x.x.x1.http: Flags [.], ack 1, win 502, options [nop,nop,TS val 2595136163 ecr 2062390218], length 0
```

#### Four-Way Handshake

```bash
16:54:28.356723 IP domain1.54028 > x.x.x.x1.http: Flags [F.], seq 1746, ack 215, win 501, options [nop,nop,TS val 2595158034 ecr 2062412087], length 0
16:54:28.557169 IP x.x.x.x1.http > domain1.54028: Flags [F.], seq 215, ack 1747, win 477, options [nop,nop,TS val 2062412289 ecr 2595158034], length 0
16:54:28.557222 IP domain1.54028 > x.x.x.x1.http: Flags [.], ack 216, win 501, options [nop,nop,TS val 2595158234 ecr 2062412289], length 0
```

#### tcpdump Flags

- Tcpdump flags are flags that indicate TCP connection status or actions. They are usually represented in square brackets in tcpdump output. There are various flags in tcpdump output, and the output may also contain combinations of multiple TCP flags. Some common flags include:
  - S (SYN): This flag is used to establish a connection between two hosts. It is set in the first packet of the three-way handshake.
  - . (No flag): This means no flag is set in the packet. It is usually used for data transmission or acknowledgment packets.
  - P (PUSH): This flag is used to indicate that the sender wants to send data as soon as possible without waiting for the buffer to fill.
  - F (FIN): This flag is used to terminate the connection between two hosts. It is set in the last packet of the four-way handshake.
  - R (RST): This flag is used to reset connections that are in an invalid state or encounter errors. It is also used to reject unwanted connection attempts.
  - W (ECN CWR): This flag is used to indicate that the sender has reduced its congestion window size according to the network's Explicit Congestion Notification (ECN).
  - E (ECN-Echo): This flag is used to indicate that the receiver has received a packet with the ECN bit, meaning there is congestion in the network.
- For example, a packet with flags [S.] means it is a SYN packet, the first step in establishing a TCP connection. A packet with flags [P.] means it is a PUSH packet containing data that the sender wants to transmit quickly. A packet with flags [F.] means it is a FIN packet, the last step in closing a TCP connection.

#### Why tcpdump Four-Way Handshake Only Has Three Packets

- The reason tcpdump four-way handshake only has three packets may be due to the following:
  - One possibility is that the passive closing party (the one receiving FIN) sends its own FIN while replying with ACK, combining the second and third handshakes into one packet, saving one packet. In this case, the passive closing party has no more data to send, so it can directly enter the LAST_ACK state and wait for the final ACK from the active closing party.
  - Another possibility is that the active closing party (the one sending FIN) doesn't reply with ACK promptly after receiving the passive closing party's FIN, but sends ACK after some time with the RST flag set, indicating a forced connection reset. In this case, the active closing party may have encountered an exception or timeout, so it no longer waits for the 2MSL time but directly enters the CLOSE state.
  - Another possibility is that tcpdump didn't capture all packets due to network delay or packet loss, causing certain handshake packets not to be captured. In this case, you can try re-capturing packets or increasing the capture time range to see if you can see the complete four-way handshake process.

### Actual Data

```bash
$ python oss.py --file_input=./1K.data --file_output=./download-1M.data --region=us --model=3 --range=5
encrypted_upload
http://domain1 upload ./1K.data, encrypt cost 1.530029296875, upload cost 408.5546875
```

```bash
$ sudo tcpdump -i bond0 | grep x.x.x.x1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on bond0, link-type EN10MB (Ethernet), capture size 262144 bytes

16:54:06.286416 IP domain1.33666 > x.x.x.x1.http: Flags [S], seq 2682796272, win 64240, options [mss 1460,sackOK,TS val 2595135963 ecr 0,nop,wscale 7], length 0
16:54:06.486797 IP x.x.x.x1.http > domain1.33666: Flags [S.], seq 2198055866, ack 2682796273, win 62643, options [mss 1460,sackOK,TS val 2062390218 ecr 2595135963,nop,wscale 7], length 0
16:54:06.486840 IP domain1.33666 > x.x.x.x1.http: Flags [.], ack 1, win 502, options [nop,nop,TS val 2595136163 ecr 2062390218], length 0
16:54:06.486930 IP domain1.33666 > x.x.x.x1.http: Flags [P.], seq 1:292, ack 1, win 502, options [nop,nop,TS val 2595136164 ecr 2062390218], length 291: HTTP: POST /upload/files HTTP/1.1
16:54:06.486960 IP domain1.33666 > x.x.x.x1.http: Flags [P.], seq 292:1746, ack 1, win 502, options [nop,nop,TS val 2595136164 ecr 2062390218], length 1454: HTTP
16:54:06.687234 IP x.x.x.x1.http > domain1.33666: Flags [.], ack 292, win 488, options [nop,nop,TS val 2062390419 ecr 2595136164], length 0
16:54:06.687279 IP x.x.x.x1.http > domain1.33666: Flags [.], ack 1746, win 477, options [nop,nop,TS val 2062390419 ecr 2595136164], length 0
16:54:06.690277 IP x.x.x.x1.http > domain1.33666: Flags [P.], seq 1:215, ack 1746, win 477, options [nop,nop,TS val 2062390422 ecr 2595136164], length 214: HTTP: HTTP/1.1 200 OK
16:54:06.690314 IP domain1.33666 > x.x.x.x1.http: Flags [.], ack 215, win 501, options [nop,nop,TS val 2595136367 ecr 2062390422], length 0
16:54:06.692023 IP domain1.33666 > x.x.x.x1.http: Flags [F.], seq 1746, ack 215, win 501, options [nop,nop,TS val 2595136369 ecr 2062390422], length 0
16:54:06.892401 IP x.x.x.x1.http > domain1.33666: Flags [F.], seq 215, ack 1747, win 477, options [nop,nop,TS val 2062390624 ecr 2595136369], length 0
16:54:06.892448 IP domain1.33666 > x.x.x.x1.http: Flags [.], ack 216, win 501, options [nop,nop,TS val 2595136569 ecr 2062390624], length 0
```

- Actually uploading 1M of data for analysis, simplified here.
- Since all time jumps occur in packets returned from the server side, the problem is now very clear. Due to the actual physical distance between Shenzhen and the US East Coast, the 200ms round trip has reached its limit. So it's actually reasonable.

## Soul-Searching Question

- At this point, a soul-searching question arises: why was it faster when using the public network before?
- After communicating with colleagues from sister departments and simulating their code, we tested using AWS SDK

```python
import boto3
from boto3.s3.transfer import TransferConfig

def download():
    s3_client = client(access_key, access_secret, host)
    GB = 1024 ** 3
    config = TransferConfig(multipart_threshold=2 * GB, max_concurrency=10, use_threads=True)
    s3_client.download_file(Bucket="bucket", Key="name-100.jpg", Filename="name-100.jpg", Config=config)

if __name__ == '__main__':
    download()
    # ...
    download()
```

**Results**

```bash
2.359457492828369
2.34989070892334
2.4120875199635825
2.3953704833984375
2.382766008377075
2.3793430725733438
2.3801622731345042
2.374732166528702
2.393121269014147
2.387941288948059
2.3849898034876045
2.3809364239374795
2.382789208338811
2.379830701010568
2.3768802642822267
2.3746740520000458
2.374574675279505
2.3716080056296454
```

- As you can see, using aws-sdk was actually slower. This was even stranger - why couldn't we reproduce the results from the sister department?
- First, the `max_concurrency=10` in the config gave me some confusion. The client definitely supports thread pools, but it didn't seem to be used because a new client was initialized each time.

**Optimization**

- So we tested with client reuse

```python
def download():
    s3_client = client(access_key, access_secret, host)
    GB = 1024 ** 3
    config = TransferConfig(multipart_threshold=2 * GB, max_concurrency=10, use_threads=True)
    now = time.time()
    count = 0

    while count < 20:
        s3_client.download_file(Bucket="bucket", Key="name-100.jpg", Filename="name-100.jpg", Config=config)
        count += 1
        print((time.time() - now) / count)
```

**Results**

```bash
download
2.465491533279419
1.5669758319854736
1.2221351464589436
1.0315884947776794
0.9212518692016601
0.8434466520945231
0.7922392232077462
0.7573718726634979
0.7251839107937283
0.6981703996658325
0.6772929538380016
0.6588474710782369
0.6429501130030706
0.6297299180712018
0.6190152009328206
0.6086597740650177
0.5995960656334373
0.5917102760738797
0.585765048077232
0.5791293740272522
```

- Based on the results, we found that it was just assumed that the default framework reuses all connections. After modifying to reuse connections, the effect was excellent.
- And it's approaching the theoretical limit of 200ms (infinite bandwidth, one interaction)

## Initial Conclusion

- First, regarding how to accelerate transmission, we already have the most direct conclusion. Reuse connections, and below is a comparison for 1M files

### Comparison Between Connection Reuse and Non-Reuse

```bash
$ python oss.py --file_input=./1M.data --file_output=./download-1M.data --region=us --model=3 --range=5
encrypted_upload
http://domain1 upload ./1M.data, encrypt cost 4.924560546875, upload cost 1919.100341796875
http://domain1 upload ./1M.data, encrypt cost 4.593017578125, upload cost 1715.593994140625
http://domain1 upload ./1M.data, encrypt cost 10.076171875, upload cost 2253.67333984375
http://domain1 upload ./1M.data, encrypt cost 12.694091796875, upload cost 1714.197021484375
http://domain1 upload ./1M.data, encrypt cost 12.3076171875, upload cost 2152.773193359375
```

## Continued Questioning

- Originally, everything should have ended here. Reuse connections and efficiency improves dramatically. It's unrelated to the server, only related to the client. The client was handed over to the sister department for modification.
- Until the sister department reported a problem - why does the server disconnect connections?
- Through online research and checking source code default values, I found:
  1. The server supports 8192 connections by default
  2. Default client connection timeout is 30 minutes or never
- Obviously, neither matches the facts
- Then the sister department started monitoring connection status and found that connections quickly entered CLOSE_WAIT state. Obviously, the server received FIN packets. To explain this situation, through packet capture, we actually proved that the sister department's code issue caused FIN packets to be sent.
- Since I highly value using packet capture and monitoring connection status to find problems, I planned to reproduce the previous situation to introduce packet capture tools and methods. But during the reproduction process, I started soul-searching again

### Why Is the Efficiency Optimization So Significant?

- According to naive thinking, reusing connections should save the three-way handshake and four-way handshake, which according to the above understanding, should only optimize about 400ms. However, the reality is not like this - it's second-level optimization. Why is this?

```bash
# Naive thinking of non-reused connection packet transmission
1. [S][P][P][P][P][F]
2.                   [S][P][P][P][P][F]
3.                                     [S][P][P][P][P][F]
# Naive thinking of reused connection packet transmission
1. [S][P][P][P][P]
2.                [P][P][P][P]
3.                            [P][P][P][P][F]
```

```bash
$ python oss-muti.py --file_input=./1M.data --file_output=./download-1M.data --region=us --model=3 --range=5
encrypted_upload
http://domain1 upload ./1M.data, encrypt cost 5.02880859375, upload cost 2589.014892578125
http://domain1 upload ./1M.data, encrypt cost 10.720947265625, upload cost 562.706787109375
http://domain1 upload ./1M.data, encrypt cost 11.202392578125, upload cost 370.651611328125
http://domain1 upload ./1M.data, encrypt cost 10.948486328125, upload cost 372.409423828125
http://domain1 upload ./1M.data, encrypt cost 11.99560546875, upload cost 371.28759765625
```

- So we captured packets again for deeper investigation

### 100K Data Comparison (Return packets omitted)

```bash
$ python oss.py --file_input=./100K.data --file_output=./100K.data --region=us --model=3 --range=5
encrypted_upload
http://domain1 upload ./100K.data, encrypt cost 1.81884765625, upload cost 1017.35791015625
http://domain1 upload ./100K.data, encrypt cost 1.159912109375, upload cost 1021.509521484375
http://domain1 upload ./100K.data, encrypt cost 1.11669921875, upload cost 1016.612548828125
http://domain1 upload ./100K.data, encrypt cost 1.128662109375, upload cost 1016.171875
http://domain1 upload ./100K.data, encrypt cost 0.9912109375, upload cost 1016.228759765625
```

```bash
$ sudo tcpdump -i bond0 | grep x.x.x.x1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on bond0, link-type EN10MB (Ethernet), capture size 262144 bytes
17:16:03.069540 IP domain1.53580 > x.x.x.x1.http: Flags [S], seq 4211566581, win 64240, options [mss 1460,sackOK,TS val 2596452757 ecr 0,nop,wscale 7], length 0
17:16:03.270682 IP x.x.x.x1.http > domain1.53580: Flags [S.], seq 1741768869, ack 4211566582, win 62643, options [mss 1460,sackOK,TS val 2063707002 ecr 2596452757,nop,wscale 7], length 0
17:16:03.270850 IP domain1.53580 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596452958 ecr 2063707002], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:03.680467 IP domain1.53580 > x.x.x.x1.http: Flags [P.], seq 72694:74142, ack 1, win 502, options [nop,nop,TS val 2596453367 ecr 2063707405], length 1448: HTTP
17:16:03.874400 IP domain1.53580 > x.x.x.x1.http: Flags [P.], seq 101758:103124, ack 1, win 502, options [nop,nop,TS val 2596453561 ecr 2063707606], length 1366: HTTP
17:16:04.082005 IP x.x.x.x1.http > domain1.53580: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063707813 ecr 2596453561], length 214: HTTP: HTTP/1.1 200 OK

17:16:04.083769 IP domain1.53580 > x.x.x.x1.http: Flags [F.], seq 103124, ack 215, win 501, options [nop,nop,TS val 2596453771 ecr 2063707813], length 0
17:16:04.090059 IP domain1.44338 > x.x.x.x1.http: Flags [S], seq 3876376673, win 64240, options [mss 1460,sackOK,TS val 2596453777 ecr 0,nop,wscale 7], length 0
17:16:04.284937 IP x.x.x.x1.http > domain1.53580: Flags [F.], seq 215, ack 103125, win 442, options [nop,nop,TS val 2063708016 ecr 2596453771], length 0
17:16:04.291110 IP x.x.x.x1.http > domain1.44338: Flags [S.], seq 27078140, ack 3876376674, win 62643, options [mss 1460,sackOK,TS val 2063708023 ecr 2596453777,nop,wscale 7], length 0
17:16:04.291270 IP domain1.44338 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596453978 ecr 2063708023], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:04.693394 IP domain1.44338 > x.x.x.x1.http: Flags [P.], seq 42286:43734, ack 1, win 502, options [nop,nop,TS val 2596454380 ecr 2063708425], length 1448: HTTP
17:16:04.720945 IP domain1.44338 > x.x.x.x1.http: Flags [P.], seq 72694:74142, ack 1, win 502, options [nop,nop,TS val 2596454408 ecr 2063708425], length 1448: HTTP
17:16:04.894505 IP domain1.44338 > x.x.x.x1.http: Flags [P.], seq 101838:103124, ack 1, win 502, options [nop,nop,TS val 2596454582 ecr 2063708626], length 1286: HTTP
17:16:05.105003 IP x.x.x.x1.http > domain1.44338: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063708837 ecr 2596454582], length 214: HTTP: HTTP/1.1 200 OK

17:16:05.106641 IP domain1.44338 > x.x.x.x1.http: Flags [F.], seq 103124, ack 215, win 501, options [nop,nop,TS val 2596454794 ecr 2063708837], length 0
17:16:05.112610 IP domain1.44340 > x.x.x.x1.http: Flags [S], seq 1962726172, win 64240, options [mss 1460,sackOK,TS val 2596454800 ecr 0,nop,wscale 7], length 0
17:16:05.307713 IP x.x.x.x1.http > domain1.44338: Flags [F.], seq 215, ack 103125, win 442, options [nop,nop,TS val 2063709039 ecr 2596454794], length 0
17:16:05.313623 IP x.x.x.x1.http > domain1.44340: Flags [S.], seq 2582074627, ack 1962726173, win 62643, options [mss 1460,sackOK,TS val 2063709045 ecr 2596454800,nop,wscale 7], length 0
17:16:05.313779 IP domain1.44340 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596455001 ecr 2063709045], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:05.515156 IP domain1.44340 > x.x.x.x1.http: Flags [P.], seq 36494:39390, ack 1, win 502, options [nop,nop,TS val 2596455202 ecr 2063709246], length 2896: HTTP
17:16:05.739645 IP domain1.44340 > x.x.x.x1.http: Flags [P.], seq 68350:69798, ack 1, win 502, options [nop,nop,TS val 2596455427 ecr 2063709448], length 1448: HTTP
17:16:05.917341 IP domain1.44340 > x.x.x.x1.http: Flags [P.], seq 103102:103124, ack 1, win 502, options [nop,nop,TS val 2596455604 ecr 2063709649], length 22: HTTP
17:16:06.123141 IP x.x.x.x1.http > domain1.44340: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063709855 ecr 2596455604], length 214: HTTP: HTTP/1.1 200 OK

17:16:06.124569 IP domain1.44340 > x.x.x.x1.http: Flags [F.], seq 103124, ack 215, win 501, options [nop,nop,TS val 2596455812 ecr 2063709855], length 0
17:16:06.130364 IP domain1.44356 > x.x.x.x1.http: Flags [S], seq 3551691514, win 64240, options [mss 1460,sackOK,TS val 2596455817 ecr 0,nop,wscale 7], length 0
17:16:06.325653 IP x.x.x.x1.http > domain1.44340: Flags [F.], seq 215, ack 103125, win 442, options [nop,nop,TS val 2063710057 ecr 2596454794], length 0
17:16:06.331375 IP x.x.x.x1.http > domain1.44356: Flags [S.], seq 3143448434, ack 3551691515, win 62643, options [mss 1460,sackOK,TS val 2063710063 ecr 2596455817,nop,wscale 7], length 0
17:16:06.331580 IP domain1.44356 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596456019 ecr 2063710063], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:06.532839 IP domain1.44356 > x.x.x.x1.http: Flags [P.], seq 36494:39390, ack 1, win 502, options [nop,nop,TS val 2596456220 ecr 2063710264], length 2896: HTTP
17:16:06.733906 IP domain1.44356 > x.x.x.x1.http: Flags [P.], seq 68350:69798, ack 1, win 502, options [nop,nop,TS val 2596456421 ecr 2063710465], length 1448: HTTP
17:16:06.934842 IP domain1.44356 > x.x.x.x1.http: Flags [P.], seq 103102:103124, ack 1, win 502, options [nop,nop,TS val 2596456622 ecr 2063710666], length 22: HTTP
17:16:07.140676 IP x.x.x.x1.http > domain1.44356: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063710872 ecr 2596456622], length 214: HTTP: HTTP/1.1 200 OK

17:16:07.142071 IP domain1.44356 > x.x.x.x1.http: Flags [F.], seq 103124, ack 215, win 501, options [nop,nop,TS val 2596456829 ecr 2063710872], length 0
17:16:07.147323 IP domain1.44368 > x.x.x.x1.http: Flags [S], seq 402085581, win 64240, options [mss 1460,sackOK,TS val 2596456834 ecr 0,nop,wscale 7], length 0
17:16:07.343075 IP x.x.x.x1.http > domain1.44356: Flags [F.], seq 215, ack 103125, win 442, options [nop,nop,TS val 2063711075 ecr 2596456829], length 0
17:16:07.348425 IP x.x.x.x1.http > domain1.44368: Flags [S.], seq 2536787598, ack 402085582, win 62643, options [mss 1460,sackOK,TS val 2063711080 ecr 2596456834,nop,wscale 7], length 0
17:16:07.348648 IP domain1.44368 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596457036 ecr 2063711080], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:07.550153 IP domain1.44368 > x.x.x.x1.http: Flags [P.], seq 36494:39390, ack 1, win 502, options [nop,nop,TS val 2596457237 ecr 2063711281], length 2896: HTTP
17:16:07.751340 IP domain1.44368 > x.x.x.x1.http: Flags [P.], seq 68350:69798, ack 1, win 502, options [nop,nop,TS val 2596457438 ecr 2063711483], length 1448: HTTP
17:16:07.952350 IP domain1.44368 > x.x.x.x1.http: Flags [P.], seq 103102:103124, ack 1, win 502, options [nop,nop,TS val 2596457639 ecr 2063711684], length 22: HTTP
17:16:08.158407 IP x.x.x.x1.http > domain1.44368: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063711890 ecr 2596457639], length 214: HTTP: HTTP/1.1 200 OK

17:16:08.159502 IP domain1.44368 > x.x.x.x1.http: Flags [F.], seq 103124, ack 215, win 501, options [nop,nop,TS val 2596457847 ecr 2063711890], length 0
17:16:08.360623 IP x.x.x.x1.http > domain1.44368: Flags [F.], seq 215, ack 103125, win 442, options [nop,nop,TS val 2063712092 ecr 2596457847], length 0
```

```bash
$ python oss-muti.py --file_input=./100K.data --file_output=./100K.data --region=us --model=3 --range=5
encrypted_upload
http://domain1 upload ./100K.data, encrypt cost 1.713134765625, upload cost 1019.947265625
http://domain1 upload ./100K.data, encrypt cost 1.129638671875, upload cost 438.734375
http://domain1 upload ./100K.data, encrypt cost 0.930419921875, upload cost 268.240966796875
http://domain1 upload ./100K.data, encrypt cost 0.880615234375, upload cost 253.253662109375
http://domain1 upload ./100K.data, encrypt cost 1.1396484375, upload cost 254.03173828125
```

```bash
$ sudo tcpdump -i bond0 | grep x.x.x.x1
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on bond0, link-type EN10MB (Ethernet), capture size 262144 bytes
17:16:58.582227 IP public1.alidns.com.domain > domain1.46151: 50311 1/0/1 A x.x.x.x1 (88)
17:16:58.582538 IP domain1.59132 > x.x.x.x1.http: Flags [S], seq 2857978823, win 64240, options [mss 1460,sackOK,TS val 2596508270 ecr 0,nop,wscale 7], length 0
17:16:58.783718 IP x.x.x.x1.http > domain1.59132: Flags [S.], seq 4037665047, ack 2857978824, win 62643, options [mss 1460,sackOK,TS val 2063762515 ecr 2596508270,nop,wscale 7], length 0
17:16:58.784028 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 1:294, ack 1, win 502, options [nop,nop,TS val 2596508471 ecr 2063762515], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:59.186612 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 42286:43734, ack 1, win 502, options [nop,nop,TS val 2596508874 ecr 2063762918], length 1448: HTTP
17:16:59.214991 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 72694:74142, ack 1, win 502, options [nop,nop,TS val 2596508902 ecr 2063762918], length 1448: HTTP
17:16:59.387945 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 101758:103124, ack 1, win 502, options [nop,nop,TS val 2596509075 ecr 2063763119], length 1366: HTTP
17:16:59.594321 IP x.x.x.x1.http > domain1.59132: Flags [P.], seq 1:215, ack 103124, win 442, options [nop,nop,TS val 2063763326 ecr 2596509075], length 214: HTTP: HTTP/1.1 200 OK

17:16:59.600269 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 103124:103417, ack 215, win 501, options [nop,nop,TS val 2596509288 ecr 2063763326], length 293: HTTP: POST /upload/files HTTP/1.1
17:16:59.616693 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 141065:142513, ack 215, win 501, options [nop,nop,TS val 2596509304 ecr 2063763326], length 1448: HTTP
17:16:59.807008 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 171284:172921, ack 215, win 501, options [nop,nop,TS val 2596509494 ecr 2063763538], length 1637: HTTP
17:16:59.828692 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 206225:206247, ack 215, win 501, options [nop,nop,TS val 2596509516 ecr 2063763560], length 22: HTTP
17:17:00.034796 IP x.x.x.x1.http > domain1.59132: Flags [P.], seq 215:429, ack 206247, win 1079, options [nop,nop,TS val 2063763766 ecr 2596509516], length 214: HTTP: HTTP/1.1 200 OK

17:17:00.038874 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 206247:206540, ack 429, win 501, options [nop,nop,TS val 2596509726 ecr 2063763766], length 293: HTTP: POST /upload/files HTTP/1.1
17:17:00.080191 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 281836:283284, ack 429, win 501, options [nop,nop,TS val 2596509768 ecr 2063763766], length 1448: HTTP
17:17:00.098087 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 309348:309370, ack 429, win 501, options [nop,nop,TS val 2596509786 ecr 2063763766], length 22: HTTP
17:17:00.304214 IP x.x.x.x1.http > domain1.59132: Flags [P.], seq 429:643, ack 309370, win 2029, options [nop,nop,TS val 2063764036 ecr 2596509786], length 214: HTTP: HTTP/1.1 200 OK

17:17:00.308554 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 309370:309663, ack 643, win 501, options [nop,nop,TS val 2596509996 ecr 2063764036], length 293: HTTP: POST /upload/files HTTP/1.1
17:17:00.349857 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 412471:412493, ack 643, win 501, options [nop,nop,TS val 2596510037 ecr 2063764036], length 22: HTTP
17:17:00.558243 IP x.x.x.x1.http > domain1.59132: Flags [P.], seq 643:857, ack 412493, win 3590, options [nop,nop,TS val 2063764290 ecr 2596510037], length 214: HTTP: HTTP/1.1 200 OK

17:17:00.563952 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 412493:412786, ack 857, win 501, options [nop,nop,TS val 2596510251 ecr 2063764290], length 293: HTTP: POST /upload/files HTTP/1.1
17:17:00.605371 IP domain1.59132 > x.x.x.x1.http: Flags [P.], seq 515594:515616, ack 857, win 501, options [nop,nop,TS val 2596510293 ecr 2063764290], length 22: HTTP
17:17:00.813565 IP x.x.x.x1.http > domain1.59132: Flags [P.], seq 857:1071, ack 515616, win 5197, options [nop,nop,TS val 2063764545 ecr 2596510293], length 214: HTTP: HTTP/1.1 200 OK

17:17:00.832862 IP domain1.59132 > x.x.x.x1.http: Flags [F.], seq 515616, ack 1071, win 501, options [nop,nop,TS val 2596510520 ecr 2063764545], length 0
17:17:01.033981 IP x.x.x.x1.http > domain1.59132: Flags [F.], seq 1071, ack 515617, win 5197, options [nop,nop,TS val 2063764765 ecr 2596510520], length 0
```

- First, it's clearly visible that after connection reuse, the number of subsequent P packet transmissions significantly decreased, corresponding to the business print times. Fewer packets but the same file size can only mean the transmission itself became larger. At this point, knowledge of TCP windows and congestion started to revive in my mind.
- The specific complete window enlargement can be tested yourself. You can clearly see that in TCP, the client's single data packet transmission gradually increases.

```bash
# Naive thinking of non-reused connection packet transmission
1. [S][P][P][P][P][F]
2.                [S][P][P][P][P][F]
3.                               [S][P][P][P][P][F]
# Naive thinking of reused connection packet transmission
1. [S][P][P][P][P]
2.                [P][P][P][P]
3.                            [P][P][P][P][F]
# Actual packet transmission
1. [S][p][p][p][p]
2.                {P}{P}
3.                      {P}{P}[F]
```

**TCP window adaptation refers to TCP dynamically adjusting the size of send and receive windows based on network conditions to achieve optimal transmission efficiency. TCP window adaptation involves the following aspects:**

1. Receive window: The number of bytes the receiver advertises to the sender that it can receive, used for flow control to prevent the sender from sending too fast and causing receiver buffer overflow.
2. Congestion window: The number of bytes the sender can send, maintained by the sender based on network congestion level, used for congestion control to prevent the sender from sending too fast and causing network congestion.
3. Sliding window: The number of bytes the sender can send, determined by the smaller value between the receive window and congestion window, used for sliding window protocol to ensure orderly and reliable data transmission.
4. Window scaling: A type of TCP header option used to extend the receive window size, allowing receivers to advertise window values exceeding 65535 bytes to adapt to high-speed networks.
5. Slow start: A congestion control algorithm used to initialize the congestion window to a small value (usually 1 MSS) after connection establishment or timeout retransmission, then increase the congestion window by 1 MSS for each received ACK, making the congestion window grow exponentially until reaching a slow start threshold (ssthresh) or packet loss occurs.
6. Congestion avoidance: A congestion control algorithm used after the congestion window reaches the slow start threshold, changing the congestion window to increase by 1 MSS per RTT, making the congestion window grow linearly until packet loss occurs.
7. Fast retransmit: A retransmission mechanism used to immediately retransmit lost segments after receiving three identical ACKs without waiting for timeout timer expiration.
8. Fast recovery: A congestion control algorithm used after fast retransmit occurs, setting the slow start threshold to half the current congestion window and setting the congestion window to the slow start threshold plus three MSS (corresponding to three duplicate ACKs), then entering the congestion avoidance phase.

**What optimizations do connection pools provide?**

1. Pre-create connections, reducing creation and destruction overhead when used.
2. Reuse connections, reducing connection creation and destruction itself.
3. Optimize transmission efficiency based on network protocols and current network conditions.
