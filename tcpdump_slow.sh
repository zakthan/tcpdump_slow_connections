#!/usr/bin/awk -f

# #
# 
# Inspired by http://www.percona.com/doc/percona-toolkit/2.1/pt-tcp-model.html
# 
# Example usage: 
# $ tcpdump -i any -s 0 -nnq -tt  'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2))  - ((tcp[12]&0xf0)>>2)) != 0)'
# 1349692787.492311 IP X.X.X.X.XXXX > X.X.X.X.XXXX: tcp 1448
# $ ./requestor.awk dump.file
# 1000000029 2012-10-08 23:39:45 X.X.X.X.XXXX 0.269577 X.X.X.X.XXXX
# #
BEGIN {
        count = 1000000000;
}
{
 # time is in unix timestamp format
 time = $1;
 # ignore after the ':'
 gsub(/\:\ .*/, "", $0);
 sport = $3;
 gsub(/.*\./, "", sport);
 dport = $5;
 gsub(/.*\./, "", dport);
 # smaller port is likely to be the server
 if (sport > dport) {
        server = $3; 
        client=$5;
        status="r";
 } else {
        server=$5;
        client =$3;
        status="s";
 } 
 # print request[client]status" "sport"->"dport;
 if (client != "" && request[client]status == "s") {
        # create new request
        request[client] = "s";
        request[client, "id"] = count++;
        request[client, "server"] = server;
        request[client, "sendStartTime"] = request[client, "sendEndTime"] = time;
        request[client, "receiveStartTime"] = request[client, "receiveEndTime"] = "";
 } else if (request[client]status == "ss") {
        request[client, "sendEndTime"] = time;
 } else if (request[client]status == "sr") {
        request[client] = "r";
        request[client, "receiveStartTime"] = request[client, "receiveEndTime"] = time;
 } else if (request[client]status == "rr") {
        request[client, "receiveEndTime"] = time;
 } else if (request[client]status == "rs") {
        # log completed request
        r = request[client, "receiveStartTime"] - request[client, "sendEndTime"];
        # nicetime needs gnu awk! 
        nicetime = strftime("%Y-%m-%d %H:%M:%S",request[client, "sendEndTime"]);
        print request[client, "id"]" "nicetime" "client" "r" "request[client, "server"];

        # create new request
        request[client] = "s";
        request[client, "id"] = count++;
        request[client, "server"] = server;
        request[client, "sendStartTime"] = request[client, "sendEndTime"] = time;
        request[client, "receiveStartTime"] = request[client, "receiveEndTime"] = "";
 } else if (request[client]status == "r") {
        # response without request
        print "ERROR:"$0;
 }
}
END {
        # flush the rest
        for (client in request) {
                if (request[client] == "r") {
                        r = request[client, "receiveStartTime"] - request[client, "sendEndTime"];
                        # nicetime needs gnu awk! 
                        nicetime = strftime("%Y-%m-%d %H:%M:%S",request[client, "sendEndTime"]);
                        print request[client, "id"]" "nicetime" "client" "r" "request[client, "server"];
                } else if (request[client] == "s") {
                        print "ERROR:"request[client, "id"]" "client" "request[client, "server"];;
                }
        }
}
