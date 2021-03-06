service instance-server
basicServerOn: port
  "forked by caller"

  | loopCount |
  loopCount := 0.
  [ true ]
    whileTrue: [ 
      [ 
      self
        gemServer: [ 
          loopCount := loopCount + 1.
          self forceBeginTransaction
            ifTrue: [ 
              "Enter transaction before calling GemServer>>gemServerTransaction:onError:, which is illegal."
              self doBeginTransaction.
              forceBeginTransaction := false ].
          self forceInternalServerError
            ifTrue: [ self error: 'internal server error' ].
          self
            gemServerTransaction: [ self handleAction ]
            beforeUnwind: [ :ex | self handleBeforeUnwind: ex ].
          (Delay forMilliseconds: 500) wait.
          self
            doTransaction: [ 
              self
                logEvent:
                  'LOOPCOUNT: ' , loopCount printString , ' : ' , actionCount printString
                object: self copy ] ]
        exceptionSet: Error
        beforeUnwind: [ :ex | 
          self
            serverError: ex
            titled: 'top-level service loop'
            inTransactionDo: [ 
              (forceBeginTransaction or: [ forceInternalServerError ])
                ifTrue: [ 
                  "acknowledge event handled"
                  actionCount := actionCount + 1 ].
              forceBeginTransaction := forceInternalServerError := false.
              self
                logEvent:
                  'LOOPCOUNT (internal error): ' , loopCount printString , ' : '
                    , actionCount printString
                object: self copy ].
          System inTransaction
            ifTrue: [ 
              "ensure that error logging info is committed ... when forceBeginTransaction was in effect"
              self doCommitTransaction ] ] ]
        on: self gemServerExceptionSet
        do: [ :ex | 
          "Handler for interactive Errors ... record for testing purposes"
          self
            interactiveErrorCommit: [ 
              (forceBeginTransaction or: [ forceInternalServerError ])
                ifTrue: [ 
                  "acknowledge event handled"
                  actionCount := actionCount + 1 ].
              forceBeginTransaction := forceInternalServerError := false.
              actionResult := #'interactiveError'.
              actionException := ex.
              self logAction: #'startBasicServerOn:...interativeError'.
              self
                logEvent:
                  'LOOPCOUNT (interactive exception): ' , loopCount printString , ' : '
                    , actionCount printString
                object: self copy ] ] ]