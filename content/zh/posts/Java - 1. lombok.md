+++
date = '2025-09-21T23:22:17+08:00'
draft = false
title = '[Java] 1. Lombok'
categories = ["Java"]
tags = ["Java", "Lombok"]
+++

## 简介

* Lombok是一款Java库，它可以自动为Java类生成一些重复性的代码，如 getter、setter、equals 和 hashCode 等方法。

## 原理

* Lombok 的工作原理是基于注解处理器 （Annotation Processor）和Java Compiler API 。

* 当 Lombok 被编译器发现时，它会使用注解处理器来修改 Java 代码。在这个过程中，Lombok 会检查类中的特定注解，并根据这些注解生成相应的代码，如
  getter、setter 等方法。

* 具体来说，Lombok 使用的是 Apache BCEL（Bytecode Engineering Library）库来直接操作 Java 字节码，而不是通过反射或运行时操作。这样一来，Lombok
  可以在编译期就进行修改，从而提高性能和效率。

## 注解

- 自定义一个纯净类Node，编译后如下

```java
public class Node {
    private Long item1;
    private String item2;
}
```

```java
public class Node {
    private Long item1;
    private String item2;

    public Node() {
    }
}
```

- 解释一下，Java编译器会自定给一个无参构造器，因为任何类不能没有构造器

### 实体类

#### @Data & @EqualsAndHashCode & @Getter & @Setter & @ToString

```java
@Data
public class Node {
    private Long item1;
    private String item2;
}
```

- 我们最常用的@Data，其实是一些基本注解的集合，比如@Getter、@Setter、@EqualsAndHashCode、@ToString

```java
public class Node {
  private Long item1;
  private String item2;

  public Node() {
  }

  public Long getItem1() {
    return this.item1;
  }

  public String getItem2() {
    return this.item2;
  }

  public void setItem1(Long item1) {
    this.item1 = item1;
  }

  public void setItem2(String item2) {
    this.item2 = item2;
  }

  public boolean equals(Object o) {
    if (o == this) {
      return true;
    } else if (!(o instanceof Node)) {
      return false;
    } else {
      Node other = (Node)o;
      if (!other.canEqual(this)) {
        return false;
      } else {
        Object this$item1 = this.getItem1();
        Object other$item1 = other.getItem1();
        if (this$item1 == null) {
          if (other$item1 != null) {
            return false;
          }
        } else if (!this$item1.equals(other$item1)) {
          return false;
        }

        Object this$item2 = this.getItem2();
        Object other$item2 = other.getItem2();
        if (this$item2 == null) {
          if (other$item2 != null) {
            return false;
          }
        } else if (!this$item2.equals(other$item2)) {
          return false;
        }

        return true;
      }
    }
  }

  protected boolean canEqual(Object other) {
    return other instanceof Node;
  }

  public int hashCode() {
    int PRIME = true;
    int result = 1;
    Object $item1 = this.getItem1();
    result = result * 59 + ($item1 == null ? 43 : $item1.hashCode());
    Object $item2 = this.getItem2();
    result = result * 59 + ($item2 == null ? 43 : $item2.hashCode());
    return result;
  }

  public String toString() {
    return "Node(item1=" + this.getItem1() + ", item2=" + this.getItem2() + ")";
  }
}
```

* 这里介绍一些基本的进阶用法

```java
@Getter
@Setter
public class Node {
    @Getter(AccessLevel.PRIVATE)
    private Long item1;
    @Setter(AccessLevel.PRIVATE)
    private String item2;
}
```

- 可以看到，设置对应的PRIVATE权限的方法变成了private。这样有利于做一些权限的集中

```java
public class Node {
    private Long item1;
    private String item2;

    public Node() {
    }

    public String getItem2() {
        return this.item2;
    }

    public void setItem1(Long item1) {
        this.item1 = item1;
    }

    private Long getItem1() {
        return this.item1;
    }

    private void setItem2(String item2) {
        this.item2 = item2;
    }
}
```

#### @AllArgsConstructor & @NoArgsConstructor & @RequiredArgsConstructor

```java
@NoArgsConstructor
@AllArgsConstructor
public class Node {
    private Long item1;
    private String item2;
}
```

- 很明显会生成无参构造器，全参构造器。必须参构造器，会与无参构造器产生冲突，所以另外展示。

```java
public class Node {
    private Long item1;
    private String item2;

    public Node() {
    }

    public Node(Long item1, String item2) {
        this.item1 = item1;
        this.item2 = item2;
    }
}
```

- 必须参构造器

```java
@RequiredArgsConstructor
@AllArgsConstructor
public class Node {
    private final Long item1;
    private String item2;
}
```

```java
public class Node {
    private final Long item1;
    private String item2;

    public Node(Long item1) {
        this.item1 = item1;
    }

    public Node(Long item1, String item2) {
        this.item1 = item1;
        this.item2 = item2;
    }
}
```

- 这里最经典的组合如下

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class Node {
    private final Long item1;
    private final Long item2;
    private final Long item3;
    @Autowired
    @Lazy
    private String lazyBean;
}
```

- 输出如下

```java
@Service
public class Node {
    private static final Logger log = LoggerFactory.getLogger(Node.class);
    private final Long item1;
    private final Long item2;
    private final Long item3;
    @Autowired
    @Lazy
    private String lazyBean;

    public Node(Long item1, Long item2, Long item3) {
        this.item1 = item1;
        this.item2 = item2;
        this.item3 = item3;
    }
}
```

- 可以看到，这里原本可以初始化的bean，依然可以初始化，有冲突或者需要lazy的，依然会遵循lazy

- 进阶一下

```java
@Service
@Slf4j
@RequiredArgsConstructor(onConstructor_ = @JsonCreator)
public class Node {
    private final Long item1;
    private final Long item2;
    private final Long item3;
    @Autowired
    @Lazy
    private String lazyBean;
}
```

- 此时输出的构造器，就会带上对应的注解。这里的语法也是Java自带的
- 另外有个点要提一下，Json序列化和反序列化的原理是先构造对象，再set对象，所以必须要有无参构造和setter。

```java
@Service
public class Node {
    private static final Logger log = LoggerFactory.getLogger(Node.class);
    private final Long item1;
    private final Long item2;
    private final Long item3;
    @Autowired
    @Lazy
    private String lazyBean;

    @JsonCreator
    public Node(Long item1, Long item2, Long item3) {
        this.item1 = item1;
        this.item2 = item2;
        this.item3 = item3;
    }
}
```

#### @Builder & @SuperBuilder & @Singular

- 众所周知，@Builder的原理是先存储数据，然后统一调用全参构造器。所以记得增加对应的全参构造即可。

```java
@AllArgsConstructor
@Builder
public class Node {
    private Long item1;
    private Long item2;
    private Long item3;
}
```

```java
public class Node {
    private Long item1;
    private Long item2;
    private Long item3;

    public static NodeBuilder builder() {
        return new NodeBuilder();
    }

    public Node(Long item1, Long item2, Long item3) {
        this.item1 = item1;
        this.item2 = item2;
        this.item3 = item3;
    }

    public static class NodeBuilder {
        private Long item1;
        private Long item2;
        private Long item3;

        NodeBuilder() {
        }

        public NodeBuilder item1(Long item1) {
            this.item1 = item1;
            return this;
        }

        public NodeBuilder item2(Long item2) {
            this.item2 = item2;
            return this;
        }

        public NodeBuilder item3(Long item3) {
            this.item3 = item3;
            return this;
        }

        public Node build() {
            return new Node(this.item1, this.item2, this.item3);
        }

        public String toString() {
            return "Node.NodeBuilder(item1=" + this.item1 + ", item2=" + this.item2 + ", item3=" + this.item3 + ")";
        }
    }
}
```

- 再展示几个进阶玩法

```java
@ToString
@AllArgsConstructor
@Builder(toBuilder = true)
public class Node {
    private Long item1;
    @Singular
    private Map<Long, Long> item2s;
    @Singular
    private List<Long> item3s;
}
```

```java
public class Node {
    private Long item1;
    private Map<Long, Long> item2s;
    private List<Long> item3s;

    public static NodeBuilder builder() {
        return new NodeBuilder();
    }

    public NodeBuilder toBuilder() {
        NodeBuilder builder = (new NodeBuilder()).item1(this.item1);
        if (this.item2s != null) {
            builder.item2s(this.item2s);
        }

        if (this.item3s != null) {
            builder.item3s(this.item3s);
        }

        return builder;
    }

    public String toString() {
        return "Node(item1=" + this.item1 + ", item2s=" + this.item2s + ", item3s=" + this.item3s + ")";
    }

    public Node(Long item1, Map<Long, Long> item2s, List<Long> item3s) {
        this.item1 = item1;
        this.item2s = item2s;
        this.item3s = item3s;
    }

    public static class NodeBuilder {
        private Long item1;
        private ArrayList<Long> item2s$key;
        private ArrayList<Long> item2s$value;
        private ArrayList<Long> item3s;

        NodeBuilder() {
        }

        public NodeBuilder item1(Long item1) {
            this.item1 = item1;
            return this;
        }

        public NodeBuilder item2(Long item2Key, Long item2Value) {
            if (this.item2s$key == null) {
                this.item2s$key = new ArrayList();
                this.item2s$value = new ArrayList();
            }

            this.item2s$key.add(item2Key);
            this.item2s$value.add(item2Value);
            return this;
        }

        public NodeBuilder item2s(Map<? extends Long, ? extends Long> item2s) {
            if (item2s == null) {
                throw new NullPointerException("item2s cannot be null");
            } else {
                if (this.item2s$key == null) {
                    this.item2s$key = new ArrayList();
                    this.item2s$value = new ArrayList();
                }

                Iterator var2 = item2s.entrySet().iterator();

                while(var2.hasNext()) {
                    Map.Entry<? extends Long, ? extends Long> $lombokEntry = (Map.Entry)var2.next();
                    this.item2s$key.add($lombokEntry.getKey());
                    this.item2s$value.add($lombokEntry.getValue());
                }

                return this;
            }
        }

        public NodeBuilder clearItem2s() {
            if (this.item2s$key != null) {
                this.item2s$key.clear();
                this.item2s$value.clear();
            }

            return this;
        }

        public NodeBuilder item3(Long item3) {
            if (this.item3s == null) {
                this.item3s = new ArrayList();
            }

            this.item3s.add(item3);
            return this;
        }

        public NodeBuilder item3s(Collection<? extends Long> item3s) {
            if (item3s == null) {
                throw new NullPointerException("item3s cannot be null");
            } else {
                if (this.item3s == null) {
                    this.item3s = new ArrayList();
                }

                this.item3s.addAll(item3s);
                return this;
            }
        }

        public NodeBuilder clearItem3s() {
            if (this.item3s != null) {
                this.item3s.clear();
            }

            return this;
        }

        public Node build() {
            Map item2s;
            switch (this.item2s$key == null ? 0 : this.item2s$key.size()) {
                case 0:
                    item2s = Collections.emptyMap();
                    break;
                case 1:
                    item2s = Collections.singletonMap(this.item2s$key.get(0), this.item2s$value.get(0));
                    break;
                default:
                    Map<Long, Long> item2s = new LinkedHashMap(this.item2s$key.size() < 1073741824 ? 1 + this.item2s$key.size() + (this.item2s$key.size() - 3) / 3 : Integer.MAX_VALUE);

                    for(int $i = 0; $i < this.item2s$key.size(); ++$i) {
                        item2s.put(this.item2s$key.get($i), (Long)this.item2s$value.get($i));
                    }

                    item2s = Collections.unmodifiableMap(item2s);
            }

            List item3s;
            switch (this.item3s == null ? 0 : this.item3s.size()) {
                case 0:
                    item3s = Collections.emptyList();
                    break;
                case 1:
                    item3s = Collections.singletonList(this.item3s.get(0));
                    break;
                default:
                    item3s = Collections.unmodifiableList(new ArrayList(this.item3s));
            }

            return new Node(this.item1, item2s, item3s);
        }

        public String toString() {
            return "Node.NodeBuilder(item1=" + this.item1 + ", item2s$key=" + this.item2s$key + ", item2s$value=" + this.item2s$value + ", item3s=" + this.item3s + ")";
        }
    }
}
```

- 此时用法如下。这里的toBuilder().build()就是一个比BeanUtils.copy效率更高的深拷贝了。不过内部对象不是深拷贝。

```java
public static void main(String[] args) {
    Node.builder()
        .item1(1L)
        .item2(2L, 3L)
        .item2(3L, 4L)
        .item3(5L)
        .item3(6L)
        .build()
        .toBuilder()
        .build();
}
```

- 相比之下，builder模式更加清晰和易读，唯一的缺点是需要构建一个轻量的Builder对象。
- 总体来讲是推荐Builder进行创建对象的。核心是配合toBuilder和Singular，保证原始对象不会变化。

#### @Sl4j

- 没啥可说的，都知道

```java
@Slf4j
public class Node {
  private Long item1;
  private Long item2;
  private Long item3;
}


public class Node {
    private static final Logger log = LoggerFactory.getLogger(Node.class);
    private Long item1;
    private Long item2;
    private Long item3;

    public Node() {
    }
}
```

## 如何自定义

- lombok的原理是通过Java自己带的编译API，自己进行的增强，所以我们按照这个思路也去增强即可。
- 核心是继承并实现类javax.annotation.processing.AbstractProcessor
- 然后通过该类的process方法，修改内部的JavacTrees相关变量即可。
- 我是已经写了一个通用图的基类，简单介绍下

```java
public abstract class BaseProcessor<T extends Annotation> extends AbstractProcessor {

    /** annotation type */
    protected Class<T> clazz;
    /** javac trees */
    protected JavacTrees trees;
    /** AST */
    protected TreeMaker treeMaker;
    /** mark name */
    protected Names names;
    /** log */
    protected Messager messager;
    /** filer */
    protected Filer filer;
    /** the jcTrees generated by annotation to add */
    protected List<JCTree> annotationJCTrees;

    @Override
    public synchronized void init(ProcessingEnvironment processingEnv) {
        super.init(processingEnv);
        // transfer type T to Class
        final Type superclass = getClass().getGenericSuperclass();
        if (superclass instanceof ParameterizedType) {
            this.clazz = (Class<T>) ((ParameterizedType) superclass).getActualTypeArguments()[0];
        } else {
            this.clazz = null;
        }
        this.trees = JavacTrees.instance(processingEnv);
        this.messager = processingEnv.getMessager();
        this.filer = processingEnv.getFiler();
        final Context context = ((JavacProcessingEnvironment) processingEnv).getContext();
        this.treeMaker = TreeMaker.instance(context);
        this.names = Names.instance(context);
        // init list
        annotationJCTrees = List.nil();
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public final boolean process(Set<? extends TypeElement> annotations, RoundEnvironment roundEnv) {
        roundEnv.getElementsAnnotatedWith(this.clazz)
                .stream()
                .map(element -> trees.getTree(element))
                // NOTE(goody): 2022/5/5
                // tree is the class input. Modify the `JCTree` to modify the method or argus
                // `visitClassDef` runs after than `visitAnnotation`, so method `visitAnnotation` can add `annotationJCTrees` to
                // `annotationJCTrees`. `visitClassDef` will prepend all
                .forEach(tree -> tree.accept(new TreeTranslator() {
                    @Override
                    public void visitClassDef(JCTree.JCClassDecl jcClassDecl) {
                        // NOTE(goody): 2022/5/4 https://stackoverflow.com/questions/46874126/java-lang-assertionerror-thrown-by-compiler-when-adding-generated-method-with-pa
                        // setMethod var is a new Object from jcVariable, the pos should be reset to jcClass
                        treeMaker.at(jcClassDecl.pos);

                        // generate the new method or variable or something else
                        final List<JCTree> jcTrees = generate(jcClassDecl);
                        jcClassDecl.defs = jcClassDecl.defs.prependList(jcTrees);

                        // add all elements in `annotationJCTrees`
                        jcClassDecl.defs = jcClassDecl.defs.prependList(annotationJCTrees);

                        super.visitClassDef(jcClassDecl);
                    }

                    @Override
                    public void visitMethodDef(JCTree.JCMethodDecl jcMethodDecl) {
                        if (isModify(jcMethodDecl)) {
                            super.visitMethodDef(modifyDecl(jcMethodDecl));
                        } else {
                            super.visitMethodDef(jcMethodDecl);
                        }
                    }

                    @Override
                    public void visitVarDef(JCTree.JCVariableDecl jcVariableDecl) {
                        if (isModify(jcVariableDecl)) {
                            super.visitVarDef(modifyDecl(jcVariableDecl));
                        } else {
                            super.visitVarDef(jcVariableDecl);
                        }
                    }

                    @Override
                    public void visitAnnotation(JCTree.JCAnnotation jcAnnotation) {
                        super.visitAnnotation(jcAnnotation);

                        final JCTree.JCAssign[] jcAssigns = jcAnnotation.getArguments()
                                .stream()
                                .filter(argu -> argu.getKind().equals(Tree.Kind.ASSIGNMENT))
                                .map(argu -> (JCTree.JCAssign) argu)
                                .toArray(JCTree.JCAssign[]::new);

                        if (jcAssigns.length > 0) {
                            annotationGenerateJCTree(handleJCAssign(List.from(jcAssigns)));
                        }
                    }
                }));
        return true;
    }

    /**
     * subclass should implement this method to add method or variable or others
     *
     * @param jcClassDecl jcClassDecl
     * @return new JCTree list
     */
    private List<JCTree> generate(JCTree.JCClassDecl jcClassDecl) {
        final JCTree[] trees = generate()
                .toArray(JCTree[]::new);

        // method Trees
        final JCTree[] methodTrees = jcClassDecl.defs
                .stream()
                .filter(k -> k.getKind().equals(Tree.Kind.METHOD))
                .map(tree -> (JCTree.JCMethodDecl) tree)
                .flatMap(jcMethodDecl -> handleDecl(jcMethodDecl))
                .toArray(JCTree[]::new);

        // variable trees
        final JCTree[] variableTrees = jcClassDecl.defs
                .stream()
                .filter(k -> k.getKind().equals(Tree.Kind.VARIABLE))
                .map(tree -> (JCTree.JCVariableDecl) tree)
                .flatMap(jcVariable -> handleDecl(jcVariable))
                .toArray(JCTree[]::new);

        return List.from(trees)
                .prependList(List.from(variableTrees))
                .prependList(List.from(methodTrees));
    }

    /**
     * check if the method need to be modified. default false
     *
     * @param jcMethodDecl jcmethodDecl
     * @return true -> need to be modified ; false -> need not to be
     */
    protected boolean isModify(JCTree.JCMethodDecl jcMethodDecl) {
        return false;
    }

    /**
     * modify the jcMethodDecl input.
     *
     * @param jcMethodDecl metaDecl
     * @return point Decl
     */
    protected JCTree.JCMethodDecl modifyDecl(JCTree.JCMethodDecl jcMethodDecl) {
        return jcMethodDecl;
    }

    /**
     * check if the method need to be modified. default false
     *
     * @param jcVariableDecl jcmethodDecl
     * @return true -> need to be modified ; false -> need not to be
     */
    protected boolean isModify(JCTree.JCVariableDecl jcVariableDecl) {
        return false;
    }

    /**
     * modify the jcVariableDecl input.
     *
     * @param jcVariableDecl metaDecl
     * @return point Decl
     */
    protected JCTree.JCVariableDecl modifyDecl(JCTree.JCVariableDecl jcVariableDecl) {
        return jcVariableDecl;
    }

    /**
     * generate with nothing
     *
     * @return Steam of JCTree to add
     */
    protected Stream<JCTree> generate() {
        return Stream.empty();
    }

    /**
     * every jcMethodDecl will input to
     *
     * @param jcMethodDecl jcMethodDecl
     * @return Steam of JCTree to add
     */
    protected Stream<JCTree> handleDecl(JCTree.JCMethodDecl jcMethodDecl) {
        return Stream.empty();
    }

    /**
     * every jcVariableDecl will input to
     *
     * @param jcVariableDecl jcVariableDecl
     * @return Steam of JCTree to add
     */
    protected Stream<JCTree> handleDecl(JCTree.JCVariableDecl jcVariableDecl) {
        return Stream.empty();
    }

    /**
     * every annotation argu will input to
     *
     * @param jcAssign jcAssign
     */
    protected List<JCTree> handleJCAssign(List<JCTree.JCAssign> jcAssign) {
        return List.nil();
    }

    protected final void annotationGenerateJCTree(JCTree jcTree) {
        this.annotationJCTrees = this.annotationJCTrees.prepend(jcTree);
    }

    protected final void annotationGenerateJCTree(List<JCTree> jcTrees) {
        this.annotationJCTrees = this.annotationJCTrees.prependList(jcTrees);
    }
}
```

- 相对还算复杂，不过继续直接使用即可

```java
@Documented
@Retention(RetentionPolicy.SOURCE)
@Target({ElementType.TYPE})
public @interface LogSelf {
}

@SupportedAnnotationTypes({"com.goody.utils.qianliang.processor.impl.LogSelf"})
@SupportedSourceVersion(SourceVersion.RELEASE_8)
@AutoService(Processor.class)
public class ZLogSelfProcessor extends BaseProcessor<LogSelf> {

    @Override
    protected Stream<JCTree> generate() {
        try {
            return Stream.of(this.logSelf());
        } catch (Exception e) {
            return Stream.empty();
        }
    }

    /**
     * <pre>
     *  <@javax.annotation.PostConstruct()
     *  public void logSelf() {
     *      log.warn("---------- {}", this);
     *  }
     * </pre>
     */
    private JCTree logSelf() throws ClassNotFoundException, InstantiationException, IllegalAccessException {
        JCTree.JCAnnotation jcAnnotation = treeMaker.Annotation(chainDots("javax.annotation.PostConstruct"), List.nil());
        JCModifiers jcModifiers = treeMaker.Modifiers(Flags.PUBLIC, List.of(jcAnnotation));
        Name methodName = getNameFromString("logSelf");
        JCExpression returnType = treeMaker.Type((Type) (Class.forName("com.sun.tools.javac.code.Type$JCVoidType").newInstance()));
        List<JCTypeParameter> typeParameters = List.nil();
        List<JCVariableDecl> parameters = List.nil();
        List<JCExpression> throwsClauses = List.nil();
        JCBlock jcBlock = treeMaker.Block(0, List.of(treeMaker.Exec(
            treeMaker.Apply(List.nil(), chainDots("log.warn"), List.of(treeMaker.Literal("---------- {}"), treeMaker.Ident(getNameFromString("this")))))));
        JCMethodDecl method = treeMaker
            .MethodDef(jcModifiers, methodName, returnType, typeParameters, parameters, throwsClauses, jcBlock, null);
        return method;
    }

    private Name getNameFromString(String s) {
        return names.fromString(s);
    }

    public JCExpression chainDots(String element) {
        JCExpression e = null;
        String[] elems = element.split("\\.");
        for (int i = 0; i < elems.length; i++) {
            e = e == null ? treeMaker.Ident(names.fromString(elems[i]))
                : treeMaker.Select(e, names.fromString(elems[i]));
        }
        return e;
    }
}
```
