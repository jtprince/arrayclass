
class Array
  
  undef_method :flatten
  undef_method :flatten!
  #tmp_verb = $VERBOSE
  #$VERBOSE = nil
  # WARNING! Array#flatten is redefined so that it calls the is_a? method
  # (instead of doing it internally as defined in the C code).  This allows
  # Arrayclass derived objects to resist flattening by declaring that they are
  # not Arrays.  This may be _slightly_ slower than the original, but in all
  # other respects should be the same (i.e., will flatten array derived
  # classes).
  def flatten
    new_array = []
    self.each do |v|
      if v.is_a?(Array)
        new_array.push( *(v.flatten) )
      else
        new_array << v
      end
    end
    new_array
  end

  # WARNING! Array#flatten! is redefined flatten method discussed above.
  def flatten!
    self.replace(flatten)
  end
  #$VERBOSE = tmp_verb
end


module Arrayclass
  def self.new(fields)
    nclass = Class.new(Array)  
    nclass.class_eval('def self.inherited(sc)
                         sc.instance_variable_set("@arr_size", @arr_size)
                         sc.instance_variable_set("@ind", @ind.dup)
                         sc.instance_variable_set("@attributes", @attributes.dup)
                       end

                      ')

    nclass.class_eval('def self.size()
                         @arr_size 
                       end
                       def self.ind()
                         @ind
                       end
                      ')

    
    nclass.class_eval('def self.add_member(name)
                         i = @arr_size
                         self.class_eval("def #{name}() self[#{i}] end")
                         self.class_eval("def #{name}=(val) self[#{i}]=val end")
                         self.class_eval("@ind[:#{name}] = #{i}")
                         self.class_eval("@ind[\"#{name}\"] = #{i}")
                         self.class_eval("@attributes << :#{name}")
                         self.class_eval("@arr_size = @attributes.size")
                         $TMP_CRAZY = $VERBOSE; $VERBOSE = nil
                         $VERBOSE = $TMP_CRAZY
                      end')


    # This list is derived from ImageList in ImageMagick (and I've added some
    # applicable to this guy). (I've left join and zip in the
    # list of attributes since they are both handy and
    # wouldn't hurt.)
    %w(flatten flatten! assoc rassoc push pop <<).each do |att|
      nclass.class_eval("undef_method :#{att}")
    end
    nclass.class_eval("undef_method :transpose if Array.instance_methods(false).include?('transpose')")
    nclass.class_eval("@ind = {}")
    # array to preserve order
    nclass.class_eval("@attributes = []")
    nclass.class_eval("@arr_size = 0")
    fields.each_with_index do |field,i|
      nclass.add_member(field.to_s)
    end
    nclass.class_eval '
        def initialize(args=nil) 
          if args.is_a? Array
            super(args)
          elsif args.is_a? Hash 
            super(self.class.size)
            h = self.class.ind
            args.each do |k,v|
              self[h[k]] = v
            end
          else 
            super(self.class.size)
          end
        end'

    # list of 
    nclass.class_eval('def self.members() @attributes end')
    nclass.class_eval('def members() self.class.members end')
    nclass.class_eval("def is_a?(klass)
                         if klass == Array ; false
                         else ; super(klass)
                         end
                       end
                       alias_method :kind_of?, :is_a?")

    nclass.class_eval('def inspect
                         bits = members.map do |v| 
                           val = self.send(v)
                           val = "nil" if val.nil?
                           "#{v}=#{val.inspect}"
                         end
                         string = bits.join(", ")
                         "<(Arrayclass based) #{string}>"
                       end ')

    # NOTE that two separate objects will hash differently (even if their
    # content is the same!)
    nclass.class_eval('def hash() object_id end')
    nclass
  end
end

