
# Ref: http://wiki.mobileread.com/wiki/MOBI
# Ref: http://wiki.mobileread.com/wiki/PDB

set file [lindex $argv 0]
set fbin [open $file "rb"]

# Palm Database
set struct {
  A32      db_name
  "a2 b16" db_attrs 
  S   version
  I   ctime
  I   mtime
  I   btime
  I   modify_number
  I   appInfoID
  I   sortInfoID
  a4  type
  a4  creator 
  I   uniqueIDseed
  I   nextRecordListID
  S   numberOfRecords  

  *   recordInfoList {$numberOfRecords} {
    I	     recordOffset
    "a1 b8"  recordAttrs
    "a3	i"   recordID
  }
  a2  gap

  * PalmDOC 1 {
    S   compression
    S   Unused
    I   textLength
    S   recordCount
    S   recordMaxSize
    I   CurrentReadingPosition
  }

  * MobiHeader 1 {
    a4   MOBI
    I    size
    I    type
    I    encoding
    I    uuid
    I    version 
    I    OrtographicIndex
    I    InflectionIndex
    I    IndexNames
    I    IndexKeys
    I    ExtraIndex0
    I    ExtraIndex1
    I    ExtraIndex2
    I    ExtraIndex3
    I    ExtraIndex4
    I    ExtraIndex5
    I    FirstNonBookIndex
    I    FullNameLength
    I    locale
    I    inputLang
    I    outputLang
    I    minVersion
    I    firstImageIndex
    I    huffmanRecordOffset
    I    huffmanRecordCount
    I    huffmanTableOffset
    I    huffmanTableLength
    I    exthFlags
    a32  - 
    a4   -
    I    drmOffset
    I    drmCount
    I    drmSize
    I    drmFlags
    a8   -
    S    firstContentRecord
    S    lastContentRecord
    a4   -
    I    fcisRecordNumber
    I    fcisRecordCount?
    I    flisRecordNumber
    I    flisRecordCount?
    a8   -
    a4   -
    I    firstCompilationSection
    I    sizeCompilationSection
    a4   -
    I    extraRecordDataFlags
    I    indxRecordOffset 
    a4   -
    a4   -
    a4   -
    a4   -
    a4   -
    a4   -
  }
}


array set FIELDSPEC {
  a 1
  A 1
  s 2
  S 2
  i 4
  I 4
}

proc sandbox_expr {expr vars} {
  foreach {k v} $vars {
    set $k $v
  }

  return [expr $expr]
}

proc parse_struct {fbin struct {nloop 1}} {
  if {$nloop>1} {
    while {$nloop} {
      parse_struct $fbin $struct -$nloop 
      incr nloop -1
    }
    return
  }

    set field_list [list]
    set name_list  [list]
    set bytes_size 0 

    for {set i 0 ; set n [llength $struct]} {$i < $n} {incr i} {
      set field [lindex $struct $i]
      set name  [lindex $struct [incr i]]

      if {[llength $field]==2} {
        lassign $field field type 
      }
    
      if {$field eq "*"} {
        scan_struct vars $fbin $bytes_size $field_list $name_list

        set field_list [list]
        set name_list  [list]
        set bytes_size 0 

        set size_expr  [lindex $struct [incr i]]
        set sub_struct [lindex $struct [incr i]]
        

        set nrepeat  [sandbox_expr $size_expr [array get vars]]
        puts "nrepeat = $nrepeat"
        parse_struct $fbin $sub_struct $nrepeat
        
      } else {
        set field_type [string index $field 0]
        set field_size [string range $field 1 end]
    
        if {$field_size eq ""} {
          set field_size 1
        }
    
        incr bytes_size [expr {$::FIELDSPEC($field_type)*$field_size}] 
    
        lappend field_list $field
        lappend name_list  $name
      }
      
    }

    if [llength $field_list] {
        scan_struct vars $fbin $bytes_size $field_list $name_list
    }
}

proc scan_struct {varname fbin bytes_size field_list name_list} { 
  upvar $varname ret

  puts "bytes_size = $bytes_size"
  set bytes [read $fbin $bytes_size]
  binary scan $bytes $field_list {*}$name_list
  
  foreach name $name_list {
    puts "$name = [set $name]"
    set ret($name) [set $name]
  }

  return [llength $name_list]
}

parse_struct $fbin $struct

puts [format "%x" [tell $fbin]]

