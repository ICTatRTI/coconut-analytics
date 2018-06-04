# db:keep-enrollments
(doc) ->
   # _((await(Coconut.schoolsDB.allDocs({include_docs:true}))).rows).chain().pluck("doc").map((school)=> [school["KEEP Assigned Code"], school.Region]).object().value()
  regionBySchoolId = {2374: "Kakuma", 2375: "Kakuma", 2376: "Kakuma", 2377: "Dadaab", 2378: "Dadaab", 2379: "Dadaab", 2380: "Dadaab", 2381: "Dadaab", 2382: "Kakuma", 2383: "Kakuma", 2384: "Dadaab", 2385: "Dadaab", 2386: "Dadaab", 2387: "Dadaab", 2388: "Dadaab", 2389: "Dadaab", 2390: "Dadaab", 2391: "Dadaab", 2392: "Dadaab", 2393: "Dadaab", 2394: "Dadaab", 2395: "Dadaab", 2396: "Dadaab", 2397: "Dadaab", 2398: "Kakuma", 2399: "Dadaab", 2400: "Kakuma", 2401: "Dadaab", 2402: "Dadaab", 2403: "Kakuma", 2404: "Dadaab", 2405: "Dadaab", 2406: "Dadaab", 2407: "Dadaab", 2408: "Dadaab", 2409: "Dadaab", 2410: "Dadaab", 2411: "Kakuma", 2412: "Dadaab", 2413: "Dadaab", 2414: "Dadaab", 2415: "Dadaab", 2416: "Dadaab", 2417: "Kakuma", 2418: "Dadaab", 2419: "Kakuma", 2420: "Kakuma", 2421: "Kakuma", 2422: "Kakuma", 2423: "Kakuma", 2424: "Kakuma", 2425: "Dadaab", 2426: "Dadaab", 2427: "Kakuma", 2428: "Dadaab", 2429: "Kakuma", 2430: "Kakuma", 2431: "Kakuma", 2432: "Kakuma", 2433: "Dadaab", 2434: "Dadaab", 2435: "Kakuma", 2436: "Dadaab", 2437: "Dadaab", 2438: "Kakuma", 2439: "Kakuma", 2440: "Kakuma", 2441: "Dadaab", 2442: "Dadaab", 2443: "Dadaab", 2444: "Kakuma", 2445: "Kakuma", 2446: "Dadaab", 2447: "Kakuma", 2448: "Kakuma", 2449: "Kakuma", 2450: "Kakuma", 2451: "Kakuma", 2452: "Dadaab", 2453: "Dadaab", 2454: "Dadaab", 2455: "Dadaab", 2456: "Dadaab", 2457: "Kakuma", 2458: "Dadaab", 2459: "Dadaab", 2460: "Dadaab", 2461: "Dadaab", 2462: "Dadaab", 2463: "Kakuma", 2464: "Dadaab", 2465: "Dadaab"}


  if doc._id[0..9] is "enrollment"
    if doc.attendance
      for student, data of doc.attendance
        daysEligibleForAttendance = 0
        daysPresent = 0
        for date, attendanceStatus of data
          switch attendanceStatus
            when "Present"
              daysEligibleForAttendance+=1
              daysPresent+=1
            when "Absent"
              daysEligibleForAttendance+=1
            when "Half"
              daysEligibleForAttendance+=1
              daysPresent+=0.5
            when "Left", "Unknown", "Holiday"
              return

        year = doc._id[23..26]
        term = doc._id[33]
        region = regionBySchoolId[doc._id[18..21]]
        school = doc._id[18..21]
        [className, stream] = doc._id[41..].split(/-stream-/)
        student = student
        emit [year,term,region,school,className,stream,student], parseInt(daysPresent/daysEligibleForAttendance*100)
