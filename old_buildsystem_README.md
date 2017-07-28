## Usage
### Gradle
<big><pre>
repositories { 
  maven { 
    url "http://dl.bintray.com/riccardo/jme3-bullet-native" 
  } 
}
dependencies {
  compile "org.jmonkeyengine.bullet_builder:jme3-bullet-native:[<i>$VERSION</i>](https://github.com/riccardobl/jme3-bullet-builder/releases)"
}
</pre></big>

`$VERSION` has to be replaced with a tag chosen from the list below

### Versions (from newer to older)

#### Official [master](https://github.com/jMonkeyEngine/jmonkeyengine) (3.2)

`jmonkeyengine-master-3.2c`

`jmonkeyengine-master-3.2b` 

`jmonkeyengine-master-3.2a`

#### Official [master](https://github.com/jMonkeyEngine/jmonkeyengine) (3.2) -debug

`jmonkeyengine-master-3.2c-debug`

`jmonkeyengine-master-3.2b-debug` 

`jmonkeyengine-master-3.2a-debug`


Note: the `-debug` builds are compiled with less optimization and debugging informations enabled, they are slower than the other builds, and should be used _only_ for if you need to debug the native code.



### Bintray repo
https://bintray.com/riccardo/jme3-bullet-native/jme3-bullet-native
