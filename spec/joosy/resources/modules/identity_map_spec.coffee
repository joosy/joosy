describe "Joosy.Modules.Resources.IdentityMap", ->

  class Model extends Joosy.Resources.Hash
    @concern Joosy.Modules.Resources.Model
    @concern Joosy.Modules.Resources.IdentityMap

  class TestInline extends Model
    @entity 'test_inline'

  class Test extends Model
    @entity 'test'
    @map 'test_inlines', TestInline

  class TestNode extends Model
    @entity 'test_node'
    @map 'children', TestNode
    @map 'parent', TestNode

  beforeEach ->
    Model.identityReset()

  it "sets proper identity holder", ->
    expect(Test.build().__identityHolder).toEqual Model

  it "handles builds", ->
    foo = Test.build id: 1
    bar = Test.build id: 1

    expect(foo).toEqual bar

  it "handles maps", ->
    inline = TestInline.build(id: 1)
    root   = Test.build
      id: 1
      test_inlines: [{id: 1}, {id: 2}]

    inline.set('foo', 'bar')

    expect(root.get('test_inlines')[0].get('foo')).toEqual 'bar'

  it "handles nested bi-directional reference", ->
    biDirectionTestNode = TestNode.build
      id: 1
      yolo: true
      children: [{id: 2, parent: {id: 1, yolo: true}}]

    expect(biDirectionTestNode).toEqual(biDirectionTestNode.get('children')[0].get('parent'))
