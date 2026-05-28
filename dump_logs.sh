#!/bin/bash
log show --predicate 'eventMessage CONTAINS "pocketcrm"' --last 30m > /tmp/pocketcrm_log.txt
log show --predicate 'process == "TestFlight"' --last 30m | grep -iE "error|fault|com.luciosoft.pocketcrm" > /tmp/tf_log.txt
