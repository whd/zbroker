module ZBroker::LCS
  # implementation of longest common substring algorithm from
  # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Longest_common_substring
  def lcs(s1, s2)
    res = ""
    num = Array.new(s1.size) { Array.new(s2.size) }
    len = ans = 0
    lastsub = 0
    s1.scan(/./).each_with_index do |l1, i|
      s2.scan(/./).each_with_index do |l2, j|
        unless l1 == l2
          num[i][j]=0
        else
          (i==0 || j==0) ? num[i][j]=1 : num[i][j]=1 + num[i-1][j-1]
          if num[i][j] > len
            len = ans = num[i][j]
            thissub = i
            thissub -= num[i-1][j-1] unless num[i-1][j-1].nil?
            if lastsub == thissub
              res += s1[i,1]
            else
              lastsub = thissub
              res = s1[lastsub, (i+1)-lastsub]
            end
          end
        end
      end
    end
    res
  end
end
