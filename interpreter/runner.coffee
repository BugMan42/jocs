assert = require 'assert'

Stack   = require './stack'
Ast     = require '../parser/ast'
{ evaluateExpression } = require './expression'
Func = require './function'
io = require './io'
valueParser = require '../parser/value-parser'

{ NODES, STATEMENTS } = Ast

module.exports = @

@executeInstruction = (T) ->
    assert T?
    switch T.getType()
        when NODES.BLOCK_INSTRUCTIONS
            for child in T.getChildren()
                @executeInstruction child
        when NODES.DECLARATION
            declarations = T.getChild 1
            for declaration in declarations
                if declaration.getType() is NODES.ASSIGN
                    varName = declaration.child().child()
                    value = evaluateExpression declaration.getChild 1
                    Stack.defineVariable varName, value
                else if declaration.getType() is NODES.ID
                    varName = declaration.child()
                    Stack.defineVariable varName
        when NODES.BLOCK_ASSIGN
            for child in T.getChildren()
                @executeInstruction child
        when NODES.ASSIGN
            id    = T.left().left()
            value = evaluateExpression T.right()
            Stack.setVariable id, value
        when STATEMENTS.CIN
            for inputItem in T.getChildren()
                id = inputItem.child().child()
                word = io.getWord(io.STDIN)
                if word?
                    { leftover, value } = valueParser.parseInputWord word, inputItem.getType()
                    if value?
                        if leftover.length > 0
                            io.unshiftWord(io.STDIN, leftover)

                        Stack.setVariable id, value
                    else
                        Stack.setVariable id, null
                else
                    Stack.setVariable id, null

        when STATEMENTS.COUT
            for outputItem in T.getChildren()
                io.output io.STDOUT, evaluateExpression(outputItem)
        when STATEMENTS.RETURN
            value = evaluateExpression T.child()
            throw { return: yes, value }
        when STATEMENTS.NOP
            (->)() # Just add this comment to fill this lonely emptiness...
        when STATEMENTS.IF_THEN
            if evaluateExpression T.left()
                Stack.openNewScope()
                @executeInstruction T.right()
                Stack.closeScope()
        when STATEMENTS.IF_THEN_ELSE
            Stack.openNewScope()
            if evaluateExpression T.left()
                @executeInstruction T.right()
            else
                @executeInstruction T.getChild 2
            Stack.closeScope()
        when STATEMENTS.WHILE
            Stack.openNewScope()
            while evaluateExpression T.left()
                @executeInstruction T.right()
            Stack.closeScope()
        when STATEMENTS.FOR
            Stack.openNewScope()
            @executeInstruction T.getChild(0)
            while evaluateExpression T.getChild(1)
                @executeInstruction T.getChild(3)
                @executeInstruction T.getChild(2)
            Stack.closeScope()
        # TODO: Remember to add new scopes when handling for*, if, else and while statements
        #       * Its scope needs to handle also the initialization, condition and increment parts of the for statements
        else
            evaluateExpression T
