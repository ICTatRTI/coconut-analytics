class Dhis2
  constructor: (options) ->
    _(options).each (value, name) =>
      @[name] = value

  loadFromDatabase: (options) =>
    Coconut.database.get "dhis2"
    .then (result) =>
      @dhis2Doc = result

      fields = [
        "dhis2Url"
        "dhis2username"
        "dhis2password"
        "programId"
        "malariaCaseEntityId"
        "caseIdAttributeId"
        "ageAttributeId"
      ]

      _(fields).each (field) =>
        if result[field]
          @[field] = result[field]

      options.success()

    .catch (error) -> options.error(error)

  test: (options) =>
    console.log "Reachable?"
    @request
      api: "programs"
      error: (error) ->
        console.error error
        options.error error
      success: (result) =>
        options.success()

  request: (options) =>
    options.data = JSON.stringify(options.data) if options.method is "POST" or options.method is "PUT"
    $.ajax
      url: "#{@dhis2Url}/api/#{options.api}"
#      beforeSend: (xhr) ->
#        xhr.setRequestHeader("Authorization", "Basic " + btoa(@dhis2username + ":" + @dhis2password))

      username: @dhis2username
      password: @dhis2password
      method: options.method or "GET"
      contentType: "application/json"
      xhrFields:
        withCredentials: true
      data: options.data
      error: (error) ->
        console.log error
        options?.error?(error)
      success: (response) -> options.success(response)

  trackedEntityInstanceIdForCaseId: (options) =>
    @request
      api: "trackedEntityInstances"
      data:
        ou: options.organisationUnit
        program: @programId
        filter: "#{@caseIdAttributeId}:LIKE:#{options.caseId}"
      error: (error) ->
        console.log error
        options?.error(error)
      success: (response) ->
        return options.success(null) if response.rows.length is 0
          #Create new tracked entity
        if response.rows.length > 1
          console.warn "More than one match in DHIS2 for #{options.caseId}"
        options.success(response.rows[0][0])

  createTrackedEntityInstance: (options) =>
    @request
      api: "trackedEntityInstances"
      method: "POST"
      data:
        orgUnit: options.organisationUnit
        trackedEntity: @malariaCaseEntityId
      error: (error) ->
        console.log error
        options?.error(error)
      success: (result) ->
        options.success(result.reference)

  enrollTrackedEntityInstanceInProgram: (options) =>
    @request
      api: "enrollments"
      method: "POST"
      dataType: "json"
      data:
        trackedEntityInstance: options.trackedEntityInstanceId
        program: @programId
        orgUnit: options.organisationUnit
        attributes: [
          {attribute: @ageAttributeId, value: options.age}
          {attribute: @caseIdAttributeId, value: options.caseId}
        ]
      error: (error) -> console.log error
      success: (result) -> options?.success?(result)

  updateTrackedEntityInstance: (options) =>
    console.log options
    @request
      api: "trackedEntityInstances/#{options.trackedEntityInstanceId}"
      dataType: "json"
      method: "PUT"
      data:
        trackedEntity: @malariaCaseEntityId
        orgUnit: options.organisationUnit
        attributes: [
          {attribute: @ageAttributeId, value: options.age}
          {attribute: @caseIdAttributeId, value: options.caseId}
        ]
      error: (error) -> console.log error
      success: (result) ->
        console.log result
        options?.success?(result)

  createOrUpdateMalariaCase: (options) =>
    organisationUnit = options.malariaCase.facilityDhis2OrganisationUnitId()
    malariaCaseId = options.malariaCase.caseId()
    age = options.malariaCase.ageInYears()
    if age is null
      options?.error("No age for case: #{malariaCaseId}, not submitting to DHIS2")
      return
    if organisationUnit is null
      options?.error("No organisationUnit for case: #{malariaCaseId}, not submitting to DHIS2")
      return
    @trackedEntityInstanceIdForCaseId
      organisationUnit: organisationUnit
      caseId: malariaCaseId
      error: (error) -> console.error error
      success: (trackedEntityInstanceId) =>
        if trackedEntityInstanceId
          @updateTrackedEntityInstance
            trackedEntityInstanceId: trackedEntityInstanceId
            organisationUnit: organisationUnit
            age: options.malariaCase.ageInYears()
            caseId: malariaCaseId
            error: options?.error
            success: options?.success
        else
          @createTrackedEntityInstance
            organisationUnit: organisationUnit
            error: (error) -> console.error error
            success: (trackedEntityInstanceId) =>
              @enrollTrackedEntityInstanceInProgram
                trackedEntityInstanceId: trackedEntityInstanceId
                organisationUnit: organisationUnit
                age: options.malariaCase.ageInYears()
                caseId: options.malariaCase.caseId()
                error: options?.error
                success: options?.success


module.exports = Dhis2
