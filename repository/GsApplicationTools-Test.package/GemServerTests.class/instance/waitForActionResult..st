private
waitForActionResult: gemServer
  | loopCount |
  loopCount := 0.
  [ 
  loopCount := loopCount + 1.
  loopCount > 20
    ifTrue: [ self assert: false description: 'timed out waiting for result' ].
  System abortTransaction.
  gemServer messageCount > gemServer actionCount ]
    whileTrue: [ (Delay forMilliseconds: 250) wait ]