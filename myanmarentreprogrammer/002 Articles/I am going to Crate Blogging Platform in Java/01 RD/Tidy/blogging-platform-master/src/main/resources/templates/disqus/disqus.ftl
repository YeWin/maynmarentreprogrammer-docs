<#if disqusEnabled!false>
<div id="disqus_thread"></div>
<script>
            var disqus_config = function () {
                this.page.url = '${blogUrl}' + '${post.url}';
                this.page.identifier = '${post.id}';
                
            };
            var disqus_developer = 1;
            (function () {
                var d = document, s = d.createElement('script');
                s.src = 'http://${disqusName}.disqus.com/embed.js';
                s.setAttribute('data-timestamp', +new Date());
                (d.head || d.body).appendChild(s);
            })();
</script>
<noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript" rel="nofollow">comments
    powered by Disqus.</a></noscript>
</#if>