#!/home/user/bin/awk -f

# obstime_csv.awk grabs some statistics from WebSphere logs
# version 2.0
# csv output
# this script needs a gawk's function asorti()!
# license: Public Domain
# author: 

# truncate date and time US-like "[3/23/11 6:21:02:267 MSK]" to "[3/23/11/6"
function datehour(date, time) {
    return date "/" substr(time, 1, index(time, ":") - 1)
}

# convert date and time like "[3/23/11/6" (format "[m/d/y/h") into ISO 8601:2004
function isodate(datehour) {
    split(datehour, d, "/")
    return sprintf("%s%02d-%02d-%02d%s%02d", "20", d[3], substr(d[1],2), d[2], "T", d[4])
}

BEGIN {
    start="doStart ==============================================="
    bse="BSE777"
    napi="NAPI elapsed time"
    total="Total elapsed time"
    OFS=";"
    }

# count input requests
$0 ~ start {
    arr[datehour($1, $2), 1] += 1
}

# count refused requets, error BSE777
$0 ~ bse {
    arr[datehour($1, $2), 2] += 1
}

$0 ~ napi {
    arr[datehour($1, $2), 3] += 1
# sum of milliseconds by NAPI
    arr[datehour($1, $2), 4] += $(NF-1)
}

$0 ~ total {
    arr[datehour($1, $2), 5] += 1
# sum of total milliseconds
    arr[datehour($1, $2), 6] += $(NF-1)
}

END {
# begin header
    print "dateThour", "input", "refused", "count napi", "napi avg, s", "count total", "total avg, s"
# end header

    for (var in arr) {
# split index of array
        split(var, s, SUBSEP)
        dh = isodate(s[1])
# new array a[] from arr[] with isodate
        a[dh, s[2]] = arr[s[1], s[2]]
# new array b[] for later sort
        b[dh] = 1
    }
# optional and only for gawk
    delete arr
# new sorted by isodate array c[]
    n = asorti(b, c)
    for (i = 1; i <= n; i++) {
# only one line per hour will be printed, printf for autostrtonum
        printf "%s;%d;%d;", c[i], a[c[i], 1], a[c[i], 2]
        printf "%d;%.3f;", a[c[i], 3], a[c[i], 4] / (a[c[i], 3] * 1000)
        printf "%d;%.3f\n", a[c[i], 5], a[c[i], 6] / (a[c[i], 5] * 1000)
# count totals
        tinput += a[c[i], 1]
        trefused += a[c[i], 2]
        tcntnapi += a[c[i], 3]
        tmsnapi += a[c[i], 4]
        tcnttotal += a[c[i], 5]
        tmstotal += a[c[i], 6]
    }
# begin footer, only one line will be printed, printf for autostrtonum
    printf "%s;%d;%d;", "Total", tinput, trefused
    printf "%d;%.3f;", tcntnapi, tmsnapi / (tcntnapi * 1000)
    printf "%d;%.3f\n", tcnttotal, tmstotal / (tcnttotal * 1000)
# end footer
}
